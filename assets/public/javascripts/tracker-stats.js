$(function() {

    function PeerListController(container) {
	this.container = $(container);
	this.refresh = $('.refresh-info', container);
	this.toggle = $('.show-hide', container);
	this.plist = $('.peer-list', container);

	this.showing = false;
	this.refreshedOnce = false;
	this.info_hash = this.container.data('hash').info_hash;

	this._init();
    };

    PeerListController.prototype = {

	_init: function() {
	    var self = this;
	    
	    this.refresh.click(function() {
		self.hide(true);
		self.refreshPeerList(function() {
		    self.show();
		});
	    });

	    this.toggle.click(function() {
		if(!self.refreshedOnce) {
		    self.refreshPeerList(function() {
			self.show();
		    });

		    return;
		}

		if(self.showing) {
		    self.hide();
		}
		else {
		    self.show();
		}
	    });
	},

	setPeerList: function(peerList) {
	    this.peerList = peerList;
	},

	show: function() {
	    var self = this;
	    this.plist.empty();

	    if(this.peerList.length == 0) {
		this.plist.append(
		    "<div class='peer-item'><tt style='color:red;'>" + 
		      "No active peers</tt></div>");
	    }

	    $.each(this.peerList, function(i, peer) {
		var p = $("<tt></tt>");
	    
		p.append(peer.description + 
		     " (last_contact=" + peer.last_contact + 
		     ", completed=" + peer.completed + ")");
		self.plist.append(
		    $("<div class='peer-item'></div>").append(p));
	    });

	    this.showing = true;
	    this.plist.slideDown('fast');
	    this.toggle.text('hide');
	},
	
	hide: function(noToggle) {
	    var self = this;
	    this.plist.slideUp('fast');
	    this.showing = false;
	    if(!noToggle)
		this.toggle.text('show');
	},

	refreshPeerList: function(handle) {
	    this.refreshedOnce = true;
	    var self = this;

	    $.ajax({
		url: 'stats/peer_list',
		type: 'GET',
		data: $.param({info_hash: self.info_hash}),
		success: function(data) {
		    self.setPeerList(data);
		    if(handle)
			handle();
		}
	    });
	}

    };

    $('.main-info-hash-container').each(function(i, container) {
	new PeerListController(container);
    });

    function GlobalStats() {
	this.started = $('#tracker-started');
	this.uptime = $('#tracker-uptime');
	this.activePeers = $('#active-peers');
	this.activeFiles = $('#active-files');

	this.hashList = $('#info-hash-list');

	this.interval = 60000;
    }

    GlobalStats.prototype = {
	start: function() {
	    var self = this;

	    function getData() {
		$.ajax({
		    url: 'stats/global',
		    type: 'GET',
		    data: $.param({updated: self.updated}),
		    success: function(data) {
			self._updateFields(data);
			if(data.global_stats.info_hashes)
			    self._updateHashList(data);
			self.updated = data.updated;
		    }
		});
	    };

	    this.timer = setInterval(getData, this.interval);
	},

	stop: function() {
	    if(this.timer)
		clearInterval(this.timer);
	},

	_updateFields: function(data) {
	    this.started.text(data.started);
	    this.uptime.text(data.uptime);
	    this.activePeers.text(data.global_stats.active_peers);
	    this.activeFiles.text(data.global_stats.active_files);
	},

	_updateHashList: function(data) {
	    var list = $('.main-info-hash-container', this.hashList);
	    var self = this;

	    function contains(hashList, hash) {
		var result = null;
		$.each(hashList, function(i, h) {
		    var $h = $(h);
		    if($h.data('hash').info_hash == hash) {
			result = $h;
			return false;
		    }
		});

		return result;
	    };

	    var last = null;
	    $.each(data.global_stats.info_hashes, function(i, hash) {
		var c = contains(list, hash);
		if(!c) {
		    var tt = $("<div class='info-hash'><tt>info_hash: " + 
			       hash + 
			       " ( <a href='javascript:void(0)'" + 
			       " class='refresh-info'>refresh</a> )"
			       + " ( <a href='javascript:void(0)'" + 
			       " class='show-hide'>show</a> )" 
			       + "</tt></div>");
		    var container = $("<div class='main-info-hash-" + 
				      "container' data-hash='" + 
				      JSON.stringify({info_hash: hash}) + 
				      "'></div>");
		    container.append(tt);
		    container.append("<div class='peer-list'></div>");
		    container.css('display', 'none');

		    if(last)
			last.after(container);
		    else
			self.hashList.append(container);
		    last = container;

		    new PeerListController(container);
		    container.slideDown();
		}
		else
		    last = c;
	    });
	}
    };

    var updater = new GlobalStats();
    updater.start();

    var loading = $('#loading');

    loading.ajaxStart(function() {
	$(this).show();
    });

    loading.ajaxStop(function() {
	$(this).hide();
    });
});
