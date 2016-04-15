import React from 'react';
import ReactWebsocket from '../utils/websocket';
import TickerTable from './tickerTable';
import { httpGet } from '../../utils';

export default class Ticker extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      quote: {
        symbol: "NYC",
        venue: "OBEX",
        bid: 1234,
        ask: 2345,
        bidSize: 10,
        bidDepth: 100,
        askSize: 10,
        askDepth: 100,
        lastTrade: ""
      }
    };
  }

  componentWillMount() {
    httpGet(`/ob/api/venues/${this.props.venue}/stocks/${this.props.stock}/quote`)
    .then((data) => {
      if (data.ok === true) {
        this.setState({
          quote: data
        });
      }
    });
  }

  handleData(data) {
    if (data.ok === true) {
      this.setState({
        quote: data.quote
      });
    }
  }

  render() {
    return (
      <div>
        <ReactWebsocket url={`ws://localhost:4000/ob/api/ws/account/venues/${this.props.venue}/tickertape/stocks/${this.props.stock}`} onMessage={this.handleData.bind(this)} />
        <TickerTable quote={this.state.quote}/>
      </div>
    );
  }
}
