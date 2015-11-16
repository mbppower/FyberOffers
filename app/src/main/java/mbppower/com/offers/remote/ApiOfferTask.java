package mbppower.com.offers.remote;

import android.app.ProgressDialog;
import android.content.Context;
import android.content.SharedPreferences;
import android.net.Uri;
import android.os.AsyncTask;
import android.os.Handler;
import android.provider.Settings;
import android.text.TextUtils;
import android.util.Log;
import android.widget.ArrayAdapter;
import android.widget.GridView;
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
import mbppower.com.offers.fragment.OfferItemAdapter;

/**
 * Async task for API loading
 */
public class ApiOfferTask extends AsyncTask<String, Void, String> {

    private static final String TAG = "ApiOfferTask";

    private ApiHelper apiHelper;
    public ProgressDialog progressDialog;
    private Context context;
    private GridView grid;
    private OfferItemAdapter offerItemAdapter;
    public ApiOfferTask(Context context, GridView grid){
        super();
        this.context = context;
        this.grid = grid;
        this.apiHelper = new ApiHelper(context);

        // Set item adapter
        grid.setAdapter(offerItemAdapter = new OfferItemAdapter(context, new ArrayList<OfferItem>()));
        offerItemAdapter.setNotifyOnChange(true);
        offerItemAdapter.clear();
    }

    @Override
    protected void onPreExecute() {
        progressDialog = ProgressDialog.show(context, "Loading offers", "Please wait...", true, true);
    }

    @Override
    protected String doInBackground(String... params) {
        return apiHelper.getRemoteData();
    }

    @Override
    protected void onPostExecute(String response) {
        offerItemAdapter.addAll(apiHelper.getOffers(response));
        progressDialog.dismiss();
    }
}
