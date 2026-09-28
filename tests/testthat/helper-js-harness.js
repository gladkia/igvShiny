// Headless Node.js harness for exercising inst/htmlwidgets/igvShiny.js runtime behavior
// Evaluates widget factory against stubbed Shiny, igv, and DOM environments.

const fs = require('fs');

function runHarness(jsPath, scenario) {
   const src = fs.readFileSync(jsPath, 'utf8');
   const handlers = {};
   const inputs = [];
   const removed = [];
   const loaded = [];
   let factory;
   let pend = [];

   // Minimal mock DOM element with basic child and querySelector support
   function makeElement(id) {
      const children = [];
      const nodesByClass = {};
      return {
         id: id,
         shadowRoot: null,
         style: {},
         className: '',
         get firstChild() { return children[0] || null; },
         removeChild(child) {
            const idx = children.indexOf(child);
            if (idx !== -1) children.splice(idx, 1);
            else children.shift();
         },
         appendChild(child) { children.push(child); },
         get children() { return children; },
         set innerHTML(html) {
            this._html = html;
            const matches = html.matchAll(/class=['"]([^'"]+)['"]/g);
            for (const m of matches) {
               for (const cls of m[1].split(/\s+/)) {
                  if (!nodesByClass[cls]) {
                     nodesByClass[cls] = { className: cls, textContent: '' };
                  }
               }
            }
         },
         get innerHTML() {
            return this._html || '';
         },
         querySelector(sel) {
            const cls = sel.replace(/^\./, '');
            return nodesByClass[cls] || null;
         }
      };
   }

   const el = makeElement('igv1');

   global.window = global;
   global.console = Object.assign({}, console, {
      log: () => {},
      warn: () => {},
      error: () => {}
   });
   global.$ = () => ({ children: () => ({ remove() {} }) });
   global.document = {
      getElementById: (id) => (id === 'igv1' ? el : null),
      createElement: (tag) => {
         const node = makeElement('');
         node.tagName = tag.toUpperCase();
         return node;
      }
   };
   global.Shiny = {
      addCustomMessageHandler: (n, f) => { handlers[n] = f; },
      setInputValue: (k, v) => { inputs.push({ key: k, value: v }); }
   };
   global.HTMLWidgets = {
      widget: (w) => { factory = w.factory; },
      shinyMode: true
   };
   global.igv = {
      createBrowser: () => new Promise((res, rej) => pend.push({ res, rej })),
      removeBrowser: (b) => removed.push(b.g || b)
   };

   const mkBrowser = (g) => ({
      g,
      loadTrack: (c) => loaded.push(g + ':' + c.name),
      on: () => {},
      trackViews: []
   });

   eval(src);

   const w = factory(el, 500, 300);
   const opts = (g) => ({
      genomeName: g,
      stockGenome: true,
      dataMode: 'stock',
      initialLocus: 'chr1',
      moduleNS: '',
      tracks: []
   });
   const tick = () => new Promise((r) => setTimeout(r, 0));

   return (async () => {
      const results = {};

      if (!scenario || scenario === 'stale-render') {
         // Scenario 1: Stale render disposal
         w.renderValue(opts('a'));
         w.renderValue(opts('b'));
         pend[0].res({ g: 'a', on() {} });
         pend[1].res({ g: 'b', on() {} });
         await tick();
         results.staleRender = {
            removed: removed.slice(),
            activeBrowser: el.igvBrowser ? el.igvBrowser.g : null
         };
      }

      if (!scenario || scenario === 'queue-rerender') {
         // Scenario 2: Queued calls for superseded render are discarded, new ones kept
         loaded.length = 0;
         pend.length = 0;
         w.renderValue(opts('hg38'));
         handlers.loadBedGraphTrack({ elementID: 'igv1', trackName: 'forHg38', tbl: {} });
         w.renderValue(opts('mm10'));
         handlers.loadBedGraphTrack({ elementID: 'igv1', trackName: 'forMm10', tbl: {} });
         pend[1].res(mkBrowser('mm10'));
         await tick();
         results.queueRerender = {
            loaded: loaded.slice()
         };
      }

      if (!scenario || scenario === 'queue-fail') {
         // Scenario 3: Calls after createBrowser failure are dropped immediately, not queued
         loaded.length = 0;
         pend.length = 0;
         w.renderValue(opts('hg38'));
         pend[0].rej(new Error('host down'));
         await tick();
         handlers.loadBedGraphTrack({ elementID: 'igv1', trackName: 'afterFail', tbl: {} });
         const pendingAfterFail = typeof igvPendingMessages !== 'undefined' && igvPendingMessages['igv1']
            ? igvPendingMessages['igv1'].length
            : 0;
         w.renderValue(opts('mm10'));
         pend[1].res(mkBrowser('mm10'));
         await tick();
         results.queueFail = {
            pendingAfterFail: pendingAfterFail,
            loaded: loaded.slice()
         };
      }

      if (!scenario || scenario === 'queue-startup') {
         // Scenario 4: Early calls before the first renderValue are preserved (#185)
         const elFresh = makeElement('igv2');
         const prevGetEl = global.document.getElementById;
         global.document.getElementById = (id) => (id === 'igv2' ? elFresh : prevGetEl(id));
         const wFresh = factory(elFresh, 500, 300);
         pend.length = 0;
         loaded.length = 0;

         handlers.loadBedGraphTrack({ elementID: 'igv2', trackName: 'earlyStartup', tbl: {} });
         wFresh.renderValue(opts('ribo'));
         pend[0].res(mkBrowser('ribo'));
         await tick();
         results.queueStartup = {
            loaded: loaded.slice()
         };
         global.document.getElementById = prevGetEl;
      }

      if (!scenario || scenario === 'banner-escaping') {
         // Scenario 5: Error banner escapes special chars and emits igvError
         const elErr = makeElement('igv3');
         const prevGetEl = global.document.getElementById;
         global.document.getElementById = (id) => (id === 'igv3' ? elErr : prevGetEl(id));
         const wErr = factory(elErr, 500, 300);
         pend.length = 0;
         inputs.length = 0;

         wErr.renderValue({
            genomeName: "<script>alert('genome')</script>",
            stockGenome: true,
            dataMode: 'stock',
            initialLocus: 'chr1',
            moduleNS: '',
            tracks: []
         });
         pend[0].rej(new Error("<img src=x onerror=alert('err')>"));
         await tick();

         const banner = elErr.firstChild;
         const genomeNode = banner && banner.querySelector ? banner.querySelector('.igvshiny-genome-name') : null;
         const detailNode = banner && banner.querySelector ? banner.querySelector('.igvshiny-error-detail') : null;

         results.bannerEscaping = {
            hasBanner: !!banner,
            templateHTML: banner ? banner.innerHTML : null,
            genomeText: genomeNode ? genomeNode.textContent : null,
            detailText: detailNode ? detailNode.textContent : null,
            errorEvents: inputs.filter((i) => i.key === 'igvError').map((i) => i.value)
         };
         global.document.getElementById = prevGetEl;
      }

      return results;
   })();
}

if (require.main === module) {
   const jsPath = process.argv[2] || 'inst/htmlwidgets/igvShiny.js';
   const scenario = process.argv[3] || null;
   runHarness(jsPath, scenario)
      .then((res) => {
         process.stdout.write(JSON.stringify(res, null, 2) + '\n');
      })
      .catch((err) => {
         process.stderr.write(String(err && err.stack ? err.stack : err) + '\n');
         process.exit(1);
      });
}

module.exports = { runHarness };
