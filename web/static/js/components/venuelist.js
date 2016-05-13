import React from 'react';
import { connect } from 'react-redux';
import Actions from '../actions/venues';
import { Link } from 'react-router';

class VenueList extends React.Component {
  componentDidMount() {
    this.props.dispatch(Actions.fetchVenues());
  }

  render() {
    var self = this;
    return (
      <div>
        <h3>Venues</h3>
        <ul className="nav nav-tabs">
          {this.props.venues.map(function(venue){
            return <li role="presentation" key={venue.id} className={self.activeItem(self.props.params, venue.venue)}>
              <Link to={`/trade/venues/${venue.venue}`}>
                {venue.venue}
              </Link>
            </li>;
          })}
        </ul>
      </div>
    );
  }

  activeItem(venuePath, venueName) {
    if (venuePath.venue === venueName) {
      return "active";
    } else {
      return "";
    }
  }
}

const mapStateToProps = (state) => ({
  venues: state.venues.venues
});

export default connect(mapStateToProps)(VenueList);
