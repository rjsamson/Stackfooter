import React from 'react';

export default class TickerTable extends React.Component {
  render() {
    var quote = this.props.quote;

    return (
      <table className="table table-bordered">
        <thead>
          <tr>
            <th>Symbol</th>
            <th>Venue</th>
            <th>Bid</th>
            <th>Bid Size/Depth</th>
            <th>Last</th>
            <th>Last Size</th>
            <th>Ask</th>
            <th>Ask Size/Depth</th>
            <th>Last Trade</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>{quote.symbol}</td>
            <td>{quote.venue}</td>
            <td>{quote.bid || 0}</td>
            <td>{quote.bidSize || 0} / {quote.bidDepth || 0}</td>
            <td>{quote.last || 0}</td>
            <td>{quote.lastSize || 0}</td>
            <td>{quote.ask || 0}</td>
            <td>{quote.askSize || 0} / {quote.askDepth || 0}</td>
            <td>{quote.lastTrade}</td>
          </tr>
        </tbody>
      </table>
    );
  }
}
