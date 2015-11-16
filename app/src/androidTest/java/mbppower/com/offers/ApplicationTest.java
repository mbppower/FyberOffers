package mbppower.com.offers;

import android.app.Application;
import android.provider.Settings;
import android.test.ApplicationTestCase;
import android.test.mock.MockContext;

import java.net.MalformedURLException;
import java.util.HashMap;

import mbppower.com.offers.fragment.FormFragment;
import mbppower.com.offers.remote.ApiHelper;

/**
 * Simple tests for API calls
 */
public class ApplicationTest extends ApplicationTestCase<Application> {
    ApiHelper apiHelper;

    /**
     * Setup apiHelper since shared resources does not support a mock context
     */
    public ApplicationTest() {
        super(Application.class);
        apiHelper = new ApiHelper(new MockContext()){
            @Override
            public HashMap<String, String> getSettingsPreferences(){
                String unixTimestamp = getUnixTimestamp() + "";

                HashMap<String, String> params = new HashMap<>();
                params.put("appid", FormFragment.PREFS_DEFAULT_APP_ID);
                params.put("device_id", Settings.Secure.ANDROID_ID);
                params.put("ip", S_FAKE_IP);
                params.put("locale", S_FAKE_LOCALE);
                params.put("page", S_CURRENT_PAGE);
                params.put("ps_time", unixTimestamp);
                params.put("pub0", FormFragment.PREFS_DEFAULT_PUB_0);
                params.put("timestamp", unixTimestamp);
                params.put("uid", FormFragment.PREFS_DEFAULT_UID);
                params.put("offer_types", S_FAKE_OFFER_TYPE);
                return params;
            }
            @Override
            public String getApiKeyPreference(){
                return FormFragment.PREFS_DEFAULT_API_KEY;
            }
        };
    }
    /**
     * Test URL setup and hashEncoding
     */
    public void testHashEncoding() throws MalformedURLException {
        assertNotNull(apiHelper.getURL());
    }

    /**
     * Test remote service call
     */
    public void testRemoteJSONData(){
        String jsonData = apiHelper.getRemoteData();
        assertNotNull("Remote data is null", jsonData);
        assertNotSame(jsonData, "");
        assertNotNull(apiHelper.getOffers(jsonData));
        assertTrue(apiHelper.getOffers(jsonData).size() > 0);
    }
}