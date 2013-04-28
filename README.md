# Ruby-Tracker

A small BitTorrent Tracker written in Ruby. The peers are held in memory. See the [BitTorrent specifications][bt] for more details on how the protocol is defined, and what communication is to be expected from the tracker.

# Dependencies

The tracker requires `sinatra` to run.

# Usage

To start the server run

```bash
ruby lib/tracker.rb
```

It has a minimal web interface, which can be accessed at `http://localhost:<port>/` using a browser. The `port` is printed in the console when the server is started.

When creating a .torrent file (for instance with a BitTorrent client) the URL (`http://localhost:<port>/announce`) can be included in the *Trackers* field.

# License 

**This software is licensed under "MIT"**

> Copyright (c) 2012 Mirza Kapetanovic
> 
> Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the 'Software'), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
> 
> The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
> 
> THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

[bt]:http://wiki.theory.org/BitTorrentSpecification#Tracker_HTTP.2FHTTPS_Protocol "BitTorrent protocol"
