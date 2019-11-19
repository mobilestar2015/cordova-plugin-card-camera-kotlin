/*global cordova, module*/

module.exports = {
  takePictures: function (successCallback, errorCallback) {
    cordova.exec(successCallback, errorCallback, "CardCamera", "takePictures", [input]);
  }
};
