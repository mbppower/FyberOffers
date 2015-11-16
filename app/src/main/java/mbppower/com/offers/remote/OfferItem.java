package mbppower.com.offers.remote;

/**
 * Offer item for grid view representation
 * @see ApiOfferTask
 */
public class OfferItem {

    private String title;
    private Long offerId;
    private String teaser;
    private String requiredActions;
    private String link;
    private String payout;
    private String thumbnailLowres;
    private String thumbnailHires;
    private String storeId;

    public OfferItem() {
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public Long getOfferId() {
        return offerId;
    }

    public void setOfferId(Long offerId) {
        this.offerId = offerId;
    }

    public String getTeaser() {
        return teaser;
    }

    public void setTeaser(String teaser) {
        this.teaser = teaser;
    }

    public String getRequiredActions() {
        return requiredActions;
    }

    public void setRequiredActions(String requiredActions) {
        this.requiredActions = requiredActions;
    }

    public String getLink() {
        return link;
    }

    public void setLink(String link) {
        this.link = link;
    }

    public String getPayout() {
        return payout;
    }

    public void setPayout(String payout) {
        this.payout = payout;
    }

    public String getThumbnailLowres() {
        return thumbnailLowres;
    }

    public void setThumbnailLowres(String thumbnailLowres) {
        this.thumbnailLowres = thumbnailLowres;
    }

    public String getThumbnailHires() {
        return thumbnailHires;
    }

    public void setThumbnailHires(String thumbnailHires) {
        this.thumbnailHires = thumbnailHires;
    }

    public String getStoreId() {
        return storeId;
    }

    public void setStoreId(String storeId) {
        this.storeId = storeId;
    }

}
