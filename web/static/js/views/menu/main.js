import React from 'react';
import VenueList from '../../components/venuelist';

export default class MainMenu extends React.Component {
  render() {
    return (
      <div>
        {this.props.children}
      </div>
    );
  }
}
