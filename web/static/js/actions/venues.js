import { httpGet, httpPost } from '../utils';

const Actions = {
  placeOrder: (orderInfo) => {
    console.log(orderInfo);
    const order = {
      account: orderInfo.username,
      venue: orderInfo.venue,
      stock: orderInfo.symbol,
      price: orderInfo.price,
      qty: orderInfo.qty,
      direction: orderInfo.direction,
      orderType: orderInfo.orderType
    };

    const url = `/ob/api/venues/${order.venue}/stocks/${order.stock}/orders`

    return dispatch => {
      dispatch({type: 'PLACING_ORDER'});

      httpPost(url, order)
      .then((data) => {
        console.log(data);
        dispatch({
          type: 'ORDER_PLACED',
          order: data,
          venue: order.venue
        });
      });
    }
  },

  fetchVenues: () => {
    return dispatch => {
      dispatch({type: 'VENUES_FETCHING'});

      httpGet('/ob/api/venues')
      .then((data) => {
        var venues = data.venues.map(function(venue) {
          return {...venue, stocks: []}
        });

        dispatch({
          type: 'VENUES_RECEIVED',
          venues: venues
        });

        venues.forEach(function(venue) {
          dispatch(Actions.fetchStocksOnVenue(venue.venue));
        });
      });
    };
  },

  fetchStocksOnVenue: (venue) => {
    return dispatch => {
      dispatch({type: 'VENUE_STOCKS_FETCHING'});

      httpGet(`/ob/api/venues/${venue}/stocks`)
      .then((data) => {
        dispatch({
          type: 'VENUE_STOCKS_RECEIVED',
          stocks: data.symbols,
          venue: venue
        });
      });
    };
  }
}

export default Actions;
