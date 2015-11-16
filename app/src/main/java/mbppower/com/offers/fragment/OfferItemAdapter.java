package mbppower.com.offers.fragment;

import android.content.Context;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ArrayAdapter;
import android.widget.BaseAdapter;
import android.widget.ImageView;
import android.widget.TextView;
import com.squareup.picasso.Picasso;
import java.util.ArrayList;
import mbppower.com.offers.R;
import mbppower.com.offers.remote.OfferItem;

/**
 * Offers Item for the grid view
 */
public class OfferItemAdapter extends ArrayAdapter<OfferItem> {
    public final String  TAG = "OfferItemAdapter";
    private Context context;


    public OfferItemAdapter(Context context, ArrayList<OfferItem> offerList) {
        super(context, R.layout.grid_view_offer_item, offerList);
        this.context = context;
    }

    /**
     * Inflate custom view for the OfferItem representation
     */
    public View getView(int position, View convertView, ViewGroup parent) {

        // Inflate item
        if (convertView == null) {
            LayoutInflater inflater = (LayoutInflater) context.getSystemService(Context.LAYOUT_INFLATER_SERVICE);
            convertView = inflater.inflate(R.layout.grid_view_offer_item, null);
        }

        // Get Components
        ImageView imageView = (ImageView)convertView.findViewById(R.id.offer_image);
        TextView title = (TextView)convertView.findViewById(R.id.offer_title);
        TextView teaser = (TextView)convertView.findViewById(R.id.offer_teaser);
        TextView payout = (TextView)convertView.findViewById(R.id.offer_payout);

        // Set data
        OfferItem offer = getItem(position);
        Picasso.with(context).load(offer.getThumbnailHires()).into(imageView);
        title.setText(offer.getTitle());
        teaser.setText(offer.getTeaser());
        payout.setText(offer.getPayout());

        return convertView;
    }
}
