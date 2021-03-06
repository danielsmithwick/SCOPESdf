'use strict';

module.exports = Auth;

let $auth
let $footer
let $header

/**
 * Initializes the auth container
 * @returns {element} auth element
 */
function Auth() {

	console.log("-- Auth initialized")

	$auth = $('.Auth')
	$header = $('.Header')
  $footer = $('.Footer')

  setHeight()

  $(window).on('resize', setHeight)

  return $header

}

/**
 * Sets the height of the auth container to the viewport minus header and footer
 * @param {string} header element
 * @returns {element} header element
 */
function setHeight() {


  $auth.css({
    minHeight: (window.innerHeight - $footer.height() - $header.height()) + 'px'
  })

  return $auth

}
