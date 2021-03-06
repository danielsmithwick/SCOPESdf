// --------------------------  vendor  -------------------------- //
import Rails				from "rails-ujs" // might not need this
import Turbolinks 	from "turbolinks"

import "./lib/modernizr-custom"

// --------------------------  config  -------------------------- //
import * as Config 		from "./config"

// --------------------------  import initializers  -------------------------- //
import Images 				from "./init/Images"
import MobileDetect 	from "./init/MobileDetect"
import Webfonts 			from "./init/Webfonts"

// --------------------------  import modules  -------------------------- //
import ExternalLinks	from "./modules/ExternalLinks"

import Auth	from "./components/Auth"
import Carousel	from "./components/Carousel"
import Choices	from "./components/Choices"
import FileUpload	from "./components/FileUpload"
import FilterOverlay	from "./components/FilterOverlay"
import Form	from "./components/Form"
import Header	from "./components/Header"
import MultipleFieldGroups	from "./components/MultipleFieldGroups"
import MultipleInputs	from "./components/MultipleInputs"
import Slider	from "./components/Slider"
import Textarea	from "./components/Textarea"
import LessonHeader	from "./components/LessonHeader"
import Slideshow	from "./components/Slideshow"
import UserStatus	from "./components/UserStatus"
import Tooltips	from "./components/Tooltips"

var ScopesDF = {

	// Scripts that need to be run just once per request
	init: function() {

		// init Rails UJS, if we're using any Rails front-endy stuff
		Rails.start()

		// Init Turbolinks
    Turbolinks.start()

		// Scripts that needs to be only run once
		Images()
		MobileDetect()
    Webfonts()

	},

	// Scripts that need to be run each time a page is loaded
	go: function() {

		ExternalLinks()

		Auth()
		Carousel()
		Choices()
		FileUpload()
		Form()
		Header()
		MultipleFieldGroups()
		MultipleInputs()
		Slider()
		Textarea()
		FilterOverlay()
		LessonHeader()
		Slideshow()
		UserStatus()
		Tooltips()

	}

}

// Kick everything off
ScopesDF.init()

// --------------------------  turbolinks  -------------------------- //

// when turbolinks request is made...
document.addEventListener("turbolinks:request-start", function(event) {
	console.log("-- Turbolinks request start")
})

// when turbolinks has finished loading a page...
document.addEventListener("turbolinks:load", function() {
	console.log("-- Turbolinks load")
	// Execute scripts that need to be run after the page has been loaded
	ScopesDF.go()
})

// when turbolinks renders a page..
document.addEventListener("turbolinks:render", function() {
	console.log("-- Turbolinks render")
})
