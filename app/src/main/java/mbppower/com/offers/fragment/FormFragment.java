package mbppower.com.offers.fragment;

import android.app.Activity;
import android.app.Fragment;
import android.content.Context;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.EditText;
import android.widget.GridView;
import android.widget.Toast;

import java.util.Arrays;

import mbppower.com.offers.MainActivity;
import mbppower.com.offers.R;

/**
 * Settings form for API calls
 */
public class FormFragment extends Fragment {
    // Store name
    public static final String PREFS_STORE_NAME = "API_SETTINGS";

    // Store keys
    public static final String PREFS_PUB_0 = "PUB_0";
    public static final String PREFS_API_KEY = "API_ID";
    public static final String PREFS_APP_ID = "APP_ID";
    public static final String PREFS_UID = "UUID";

    // Default fake values
    public static final String PREFS_DEFAULT_PUB_0 = "campaign2";
    public static final String PREFS_DEFAULT_API_KEY = "1c915e3b5d42d05136185030892fbb846c278927";
    public static final String PREFS_DEFAULT_APP_ID = "2070";
    public static final String PREFS_DEFAULT_UID = "spiderman";

    // Components
    EditText editTextPub0;
    EditText editTextApiKey;
    EditText editTextAppId;
    EditText editTextUID;

    public FormFragment() {
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {

        return inflater.inflate(R.layout.fragment_form, container, false);
    }

    @Override
    public void onViewCreated(View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        setContent();
    }
    /**
     * Set the actions of this view
     */
    protected void setContent() {
        View view = getView();
        // Inputs
        editTextPub0 = (EditText) view.findViewById(R.id.textfield_pub0);
        editTextApiKey = (EditText) view.findViewById(R.id.textfield_api_key);
        editTextAppId = (EditText) view.findViewById(R.id.textfield_app_id);
        editTextUID = (EditText) view.findViewById(R.id.textfield_uid);

        // Actions
        Button buttonLoadDefaults = (Button) view.findViewById(R.id.button_load_defaults);
        buttonLoadDefaults.setOnClickListener(new Button.OnClickListener() {
            public void onClick(View v) {
                loadDefaults();
            }
        });
        Button buttonFetchOffers = (Button) view.findViewById(R.id.button_fetch_offers);
        buttonFetchOffers.setOnClickListener(new Button.OnClickListener() {
            public void onClick(View v) {
                ((MainActivity) getActivity()).showOffersFragment();
            }
        });

        // Set values
        setStoredSettings();
    }
    /**
     * Load default preferences
     */
    protected void loadDefaults() {
        SharedPreferences settings = getActivity().getSharedPreferences(PREFS_STORE_NAME,  Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = settings.edit();
        editor.clear();
        editor.commit();
        setStoredSettings();
        Toast.makeText(getActivity(), "Default settings restored", Toast.LENGTH_LONG).show();
    }

    @Override
    public void onDestroyView() {
        saveSettings();
        super.onDestroyView();
    }
    /**
     * Check if all fields were filled
     */
    public static boolean hasValidConfiguration(Activity activity){
        // Set values from preferences
        SharedPreferences  settings = activity.getSharedPreferences(PREFS_STORE_NAME, 0);

        // Check for empty values
        for(String k : Arrays.asList(PREFS_PUB_0, PREFS_API_KEY, PREFS_APP_ID, PREFS_UID)){
            boolean hasEmpty = settings.getString(k, "").isEmpty();
            if(hasEmpty){
                return false;
            }
        }
        return true;
    }
    /**
     * Set values from preferences
     */
    private void setStoredSettings(){
        SharedPreferences  settings = getActivity().getSharedPreferences(PREFS_STORE_NAME,  Context.MODE_PRIVATE);
        editTextPub0.setText(settings.getString(PREFS_PUB_0, PREFS_DEFAULT_PUB_0));
        editTextApiKey.setText(settings.getString(PREFS_API_KEY, PREFS_DEFAULT_API_KEY));
        editTextAppId.setText(settings.getString(PREFS_APP_ID, PREFS_DEFAULT_APP_ID));
        editTextUID.setText(settings.getString(PREFS_UID, PREFS_DEFAULT_UID));
    }
    /**
     * Update persistent preferences
     */
    private void saveSettings(){
        SharedPreferences settings = getActivity().getSharedPreferences(PREFS_STORE_NAME,  Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = settings.edit();
        editor.putString(PREFS_PUB_0, editTextPub0.getText().toString());
        editor.putString(PREFS_API_KEY, editTextApiKey.getText().toString());
        editor.putString(PREFS_APP_ID, editTextAppId.getText().toString());
        editor.putString(PREFS_UID, editTextUID.getText().toString());
        editor.commit();
    }
}
