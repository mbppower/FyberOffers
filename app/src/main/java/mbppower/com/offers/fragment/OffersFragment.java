package mbppower.com.offers.fragment;

import android.app.Fragment;
import android.os.AsyncTask;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.GridView;
import android.widget.TextView;

import java.util.ArrayList;

import mbppower.com.offers.R;
import mbppower.com.offers.remote.ApiOfferTask;

/**
 * Offers grid view fragment
 */
public class OffersFragment extends Fragment {
    GridView gridView;

    public OffersFragment() {
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        return  inflater.inflate(R.layout.fragment_offers, container, false);
    }

    @Override
    public void onViewCreated(View view, Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        gridView = (GridView)getView().findViewById(R.id.grid_view_offers);

        // Set no results view
        gridView.setEmptyView(getView().findViewById(R.id.no_results));
        buildOffersList();
    }

    /**
     * Load the offers through the API
     */
    public void buildOffersList(){
        ApiOfferTask task = new ApiOfferTask(getActivity(), gridView);
        task.executeOnExecutor(AsyncTask.THREAD_POOL_EXECUTOR);
    }
}
