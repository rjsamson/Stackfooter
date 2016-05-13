import React from 'react';
import VenueList from '../../components/venuelist';

export default class Venues extends React.Component {
  render() {
    return (
      <div>
        <div>
          <VenueList store={this.props.route.store} params={this.props.params}/>
        </div>
        <div>
          {this.props.children}
        </div>
      </div>
    );
  }
}
