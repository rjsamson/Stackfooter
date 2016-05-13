import React from 'react';
import { connect } from 'react-redux';
import Ticker from '../ticker/ticker';
import Actions from '../../actions/venues';
import OrderForm from '../../components/orderform'

class Venue extends React.Component {
  render() {
    var ticker;
    var venueName = this.props.params.venue;
    if (this.props.venueNames.includes(venueName)) {
      var venue = this.props.venues.find(function(ven) {
        return ven.venue === venueName;
      });

      var stocks = venue.stocks;

      ticker = (
        <div>
          <p><br/></p>
          <h2>Tickers for {venueName}</h2>
          <p><br/></p>
          {stocks.map(function(stock) {
            return <div key={`${venueName}-${stock.symbol}`}>
              <h3>{stock.symbol} - {stock.name}</h3>
              <Ticker venue={venueName} stock={stock.symbol} />
            </div>
          })}
          <OrderForm venue={venueName} stocks={stocks} />
        </div>
      );
    } else {
      ticker = (
        <div>
          <h1>Venue {this.props.params.venue} does not exist</h1>
        </div>
      );
    }
    return ticker;
  }
}

const mapStateToProps = (state) => ({
  venueNames: state.venues.venues.map(venue => venue.venue),
  venues: state.venues.venues
});

export default connect(mapStateToProps)(Venue);
