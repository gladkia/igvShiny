Shiny.addCustomMessageHandler("testmessage",
  function(message) {
     igvBrowser.search(message.roi);
  }
);
