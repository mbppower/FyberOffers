package mbppower.com.offers;

import android.app.Fragment;
import android.app.FragmentManager;
import android.app.FragmentTransaction;
import android.os.Bundle;
import android.support.v7.app.AppCompatActivity;
import android.support.v7.widget.Toolbar;
import android.view.Menu;
import android.view.MenuItem;
import android.widget.Toast;

import mbppower.com.offers.fragment.FormFragment;
import mbppower.com.offers.fragment.InitialFragment;
import mbppower.com.offers.fragment.OffersFragment;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        Toolbar toolbar = (Toolbar) findViewById(R.id.toolbar);
        setSupportActionBar(toolbar);
        setInitialContent();
        checkApiSettings();
    }

    @Override
    public boolean onCreateOptionsMenu(Menu menu) {
        // Inflate the menu; this adds items to the action bar if it is present.
        getMenuInflater().inflate(R.menu.menu_main, menu);
        return true;
    }

    public void setInitialContent() {
        showFragment(new InitialFragment(), "INITIAL_FRAGMENT");
    }
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        int id = item.getItemId();

        //noinspection SimplifiableIfStatement
        if (id == R.id.action_settings) {
            showFormFragment();
            return true;
        }
        else  if (id == R.id.action_offers) {
            showOffersFragment();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
    /**
     * Helper method to show a content fragment
     */
    public void showFragment(Fragment fragment,  String backStackKey){
        FragmentManager fragmentManager = getFragmentManager();
        FragmentTransaction ft = fragmentManager.beginTransaction();
        ft.replace(R.id.fragment_content, fragment);
        ft.setTransition(FragmentTransaction.TRANSIT_FRAGMENT_OPEN);
        ft.addToBackStack(backStackKey);
        ft.commit();
    }

    /**
     * Show settings form fragment
     */
    public void showFormFragment(){
        showFragment(new FormFragment(), "FORM_FRAGMENT");
    }

    /**
     * Show offers list fragment
     */
    public void showOffersFragment(){
        showFragment(new OffersFragment(), "OFFERS_FRAGMENT");
    }

    /**
     * Check for valid settings
     */
    public void checkApiSettings(){
        if(FormFragment.hasValidConfiguration(this)){
            showOffersFragment();
        }
        else{
            showFormFragment();
            Toast.makeText(this, "Please, fill all required fields", Toast.LENGTH_LONG).show();
        }
    }
}
