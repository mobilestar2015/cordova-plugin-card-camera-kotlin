/*global cordova, module*/

module.exports = {
  takePictures: function (input, successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "CardCamera", "takePictures", [input]);
  }
};
