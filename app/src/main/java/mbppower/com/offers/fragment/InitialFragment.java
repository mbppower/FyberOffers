package mbppower.com.offers.fragment;

import android.app.Fragment;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import mbppower.com.offers.R;

/**
 * Initial content of the offers app.
 */
public class InitialFragment extends Fragment {

    public InitialFragment() {
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_initial, container, false);
    }
}
