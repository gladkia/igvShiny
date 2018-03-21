Shiny.addCustomMessageHandler("showGenomicRegion",
  function(message) {
     igvBrowser.search(message.roi);
  }
);
