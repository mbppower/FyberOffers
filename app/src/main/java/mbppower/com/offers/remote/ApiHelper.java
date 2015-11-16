package mbppower.com.offers.remote;

import android.content.Context;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.Handler;
import android.provider.Settings;
import android.text.TextUtils;
import android.util.Log;
import android.widget.Toast;

import org.apache.commons.codec.digest.DigestUtils;
import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.MalformedURLException;
import java.net.URL;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;

import mbppower.com.offers.fragment.FormFragment;

/**
 * Helper for API manipulation
 */
public class ApiHelper {

    private static final String TAG = "ApiHelper";
    private static final String API_URL = "http://api.fyber.com/feed/v1/offers.json";

    // Fake values
    protected static final String S_FAKE_OFFER_TYPE = "112";
    protected static final String S_FAKE_LOCALE = "DE";
    protected static final String S_FAKE_IP = "109.235.143.113";
    protected static final String S_CURRENT_PAGE = "1";

    // Signature header key
    protected static final String SIGNATURE_HEADER_FIELD = "X-Sponsorpay-Response-Signature";
    protected String apiKey;
    protected Context context;

    public ApiHelper(Context context){
        this.context = context;
    }

    public Long getUnixTimestamp() {
        return (System.currentTimeMillis() / 1000L);
    }

    /**
     * Gererate special hashkey for this request
     */
    public String generateHashkey(String apiKey, List<String> sortedKeys, HashMap<String, String> params){
        Uri.Builder sortedParams = new Uri.Builder();
        for(String paramKey : sortedKeys){
            sortedParams.appendQueryParameter(paramKey, params.get(paramKey).toLowerCase());
        }
        String hashKeyParams = sortedParams.build().getQuery() + "&" + apiKey;
        return DigestUtils.shaHex(hashKeyParams);
    }

    /**
     * User preferences settings
     */
    public HashMap<String, String> getSettingsPreferences(){
        String unixTimestamp = getUnixTimestamp() + ""; //unix timestamp format
        SharedPreferences settings = context.getSharedPreferences(FormFragment.PREFS_STORE_NAME, Context.MODE_PRIVATE);
        HashMap<String, String> params = new HashMap<>();
        params.put("appid", settings.getString(FormFragment.PREFS_APP_ID, FormFragment.PREFS_DEFAULT_APP_ID));
        params.put("device_id", Settings.Secure.getString(context.getContentResolver(), Settings.Secure.ANDROID_ID));
        params.put("ip", S_FAKE_IP);
        params.put("locale", S_FAKE_LOCALE);
        params.put("page", S_CURRENT_PAGE);
        params.put("ps_time", unixTimestamp);
        params.put("pub0", settings.getString(FormFragment.PREFS_PUB_0, FormFragment.PREFS_DEFAULT_PUB_0));
        params.put("timestamp", unixTimestamp);
        params.put("uid", settings.getString(FormFragment.PREFS_UID, FormFragment.PREFS_DEFAULT_UID));
        params.put("offer_types", S_FAKE_OFFER_TYPE);
        return params;
    }
    /**
     * User preference API Key
     */
    public String getApiKeyPreference(){
        SharedPreferences settings = context.getSharedPreferences(FormFragment.PREFS_STORE_NAME, Context.MODE_PRIVATE);
        return settings.getString(FormFragment.PREFS_API_KEY, FormFragment.PREFS_DEFAULT_API_KEY);
    }

    /**
     * Build the request parameters and set the apiKey for signature check
     */
    public URL getURL() throws MalformedURLException{
        HashMap<String, String> params = getSettingsPreferences();

        // Order alphabetically
        List<String> sortedKeys = new ArrayList<>();
        sortedKeys.addAll(params.keySet());
        Collections.sort(sortedKeys);

        // Hashkey generation
        apiKey = getApiKeyPreference();
        String hashKey = generateHashkey(apiKey, sortedKeys, params);

        Uri.Builder queryParams = new Uri.Builder();
        for(String paramKey : sortedKeys){
            queryParams.appendQueryParameter(paramKey, params.get(paramKey).toLowerCase());
        }
        queryParams.appendQueryParameter("hashkey", hashKey);

        // Request
        return new URL(API_URL + queryParams.build().toString());
    }

    /**
     * Load JSON data from the API service
     */
    public String getRemoteData() {

        String jsonString = "";

        try {
            // Remote connection
            HttpURLConnection request = (HttpURLConnection) getURL().openConnection();
            request.setRequestMethod("GET");

            // Get response
            request.connect();

            // Read stream
            InputStream inputStream = request.getInputStream();
            BufferedReader streamReader = new BufferedReader(new InputStreamReader(inputStream, "UTF-8"));

            // Get response string
            String lineStr;
            StringBuilder responseStrBuilder = new StringBuilder();
            while ((lineStr = streamReader.readLine()) != null)
                responseStrBuilder.append(lineStr);
            jsonString = responseStrBuilder.toString();

            // Validate status
            if(request.getResponseCode() == HttpURLConnection.HTTP_OK){
                // Security check for the signature
                String signatureHash = request.getHeaderField(SIGNATURE_HEADER_FIELD);
                if(!signatureHash.equals(DigestUtils.shaHex(jsonString.concat(apiKey)))){
                    jsonString = "";
                    showToastFromBackground("Response signature is invalid");
                }
            }
            else{
                showToastFromBackground("Received invalid response: " + request.getResponseCode());
            }
        }
        catch (MalformedURLException e) {
            showToastFromBackground("API URL is invalid");
        }
        catch (IOException e) {
            showToastFromBackground("There is a problem trying to get the offers, check your settings and try again.");
            Log.d(TAG, e.getMessage() + "");
        }

        return jsonString;
    }
    /**
     * Run toast on UI Thread
     */
    private void showToastFromBackground(final String message){
        new Handler(context.getMainLooper()).post(new Runnable() {
            public void run() {
                Toast.makeText(context, message, Toast.LENGTH_LONG).show();
            }
        });
    }
    /**
     * Parse JSON into OfferItem List objects
     */
    public ArrayList<OfferItem> getOffers(String jsonString){
        ArrayList<OfferItem> offerList = new ArrayList<>();
        if(!TextUtils.isEmpty(jsonString)){
            try {
                JSONObject json = new JSONObject(jsonString);

                // Response OK
                if(json.getString("code").equals("OK")){
                    JSONArray items = json.getJSONArray("offers");

                    for (int i = 0; i < items.length(); i++) {
                        JSONObject offerObject = items.getJSONObject(i);
                        OfferItem offer = new OfferItem();

                        // Ids
                        offer.setOfferId(offerObject.getLong("offer_id"));
                        offer.setStoreId(offerObject.getString("store_id"));

                        offer.setTitle(offerObject.getString("title"));
                        offer.setTeaser(offerObject.getString("teaser"));
                        offer.setLink(offerObject.getString("link"));
                        offer.setPayout(offerObject.getString("payout"));
                        offer.setRequiredActions(offerObject.getString("required_actions"));

                        // Thumbnails
                        JSONObject thumbnail = offerObject.getJSONObject("thumbnail");
                        offer.setThumbnailHires(thumbnail.getString("hires"));
                        offer.setThumbnailLowres(thumbnail.getString("lowres"));

                        offerList.add(offer);
                    }
                }
                else {
                    // API error
                    String errorMessage = json.getString("message");
                    if(!TextUtils.isEmpty(errorMessage))
                        showToastFromBackground(json.getString("message"));
                }
            }
            catch (JSONException e) {
                showToastFromBackground("There is a problem trying to get the offers, please contact the support team.");
                Log.d(TAG, e.getMessage() + "");
            }
        }
        return offerList;
    }
}
