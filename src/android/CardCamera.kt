package cordova.plugin.cardcamera

import android.app.Activity
import android.content.Intent
import org.apache.cordova.*
import org.json.JSONArray
import org.json.JSONException
import android.util.Log
import org.json.JSONObject

class CardCamera : CordovaPlugin() {
    lateinit var context: CallbackContext

    @Throws(JSONException::class)
    override fun execute(action: String, data: JSONArray, callbackContext: CallbackContext): Boolean {
        context = callbackContext
        var result = true
        try {
            if (action == "takePictures") {
                cordova.startActivityForResult(this, CardCameraActivity.newIntent(cordova.context), CardCameraActivity.TAKE_PICTURES_REQUEST);
                result = true
            } else {
                handleError("Invalid action")
                result = false
            }
        } catch (e: Exception) {
            handleException(e)
            result = false
        }

        return result
    }


    /**
     * Handles an error while executing a plugin API method.
     * Calls the registered Javascript plugin error handler callback.
     *
     * @param errorMsg Error message to pass to the JS error handler
     */
    private fun handleError(errorMsg: String) {
        try {
            Log.e(TAG, errorMsg)
            context.error(errorMsg)
        } catch (e: Exception) {
            Log.e(TAG, e.toString())
        }

    }

    private fun handleException(exception: Exception) {
        handleError(exception.toString())
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?) {
        if (requestCode == CardCameraActivity.TAKE_PICTURES_REQUEST) {
            if (resultCode == Activity.RESULT_OK) {
                val front_pic = intent?.getStringExtra("front_pic")
                val back_pic = intent?.getStringExtra("back_pic")
                val result = JSONObject()
                result.put("front_pic", front_pic)
                result.put("back_pic", back_pic)
                context.success(result)
            } else {
                context.error("Cancelled")
            }
        }
        super.onActivityResult(requestCode, resultCode, intent)
    }

    companion object {

        protected val TAG = "CardCamera"
    }
}