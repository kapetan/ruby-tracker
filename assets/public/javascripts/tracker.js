$(function() {
	$('*[title]').tooltip();

	$('.announce-url').on('click', function() {
		$('input', this).focus().select();
		return false;
	});

	$('.expandable-list')
		.on('click', 'li', function() {
			var self = $(this);
			var body = $('.body', this);

			if(!body.is(':visible')) {
				self.addClass('visible-body');
				body.slideDown();
			} else {
				self.removeClass('visible-body');
				body.slideUp();
			}
		})
		.on('click', '.destroy-peer', function() {
			var peer = $(this).closest('.peer-entry');
			var torrent = $(this).closest('.torrent-entry');

			var data = {
				info_hash: torrent.attr('data-info-hash'),
				peer: {
					ip: peer.attr('data-ip'),
					port: peer.attr('data-port'),
					id: peer.attr('data-id')
				}
			};

			$.ajax('/', {
				type: 'POST',
				dataType: 'json',
				contentType: 'application/json',
				data: JSON.stringify(data),
				success: function() {
					peer.remove();

					if(!torrent.find('.peer-entry').length) {
						torrent.remove();
					}
				}
			});

			return false;
		})
});
