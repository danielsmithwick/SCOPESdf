'use strict';

module.exports = LessonHeader;

import Flickity from 'flickity-imagesloaded'

function LessonHeader() {

	console.log("-- LessonHeader initialized")

	let photosSelector = '.LessonHeader__photos'
	let photoSelector = '.LessonHeader__photo'

	let $status = $('.LessonHeader__photos__status')
	let $current = $status.find('.current')
	let $total = $status.find('.total')

  // Init flickity for all carousels
  let flkty = new Flickity(photosSelector, {
    cellAlign: 'center',
    cellSelector: photoSelector,
    contain: true,
    pageDots: false,
    prevNextButtons: false,
    wrapAround: true,
		imagesLoaded: true,
    percentPosition: true,
  })

  document.addEventListener("turbolinks:request-start", function() {
    flkty.destroy()
  })

	$total.html($(photoSelector).length)

	flkty.on( 'select', function() {
		$current.html(flkty.selectedIndex + 1)
	})

  return flkty


}