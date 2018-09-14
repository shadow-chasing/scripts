#!/usr/bin/env ruby

require File.expand_path('../../config/environment', __FILE__)

require 'pry'

names = [

"Christian Bale",
"Heath Ledger",
"Aaron Eckhart",
"Michael",
"Maggie Gyllenhaal",
"Gary Oldman",
"Morgan Freeman",
"Ron Dean",
"Cillian Murphy",
"Chin Han",
"Nestor Carbonell",
"Eric Roberts",
"Ritchie Coster",
"Anthony Michael",
"Keith Szarabajka",
"Colin McFarlane",
"Joshua Harto",
"Melinda McGraw",
"Nathan Gamble",
"Michael Vieau",
"Michael Stoyanov",
"William Smillie",
"Danny Goldring",
"Michael Jai",
"William Fichtner",
"Olumiji Olawumi",
"Greg Beam",
"Erik Hellman",
"Beatrice Rosen",
"Vincenzo Nicoli",
"Edison Chen",
"Andy Luther",
"James Farruggio",
"Tom McElroy",
"Will Zahrn",
"James Fierro",
"Patrick Leahy",
"Sam Derence",
"Jennifer Knox",
"Patrick Clear",
"Charles Venn",
"Winston Ellis",
"David Dastmalchian"
]

names.each do |name_actor|
    Movie.find_by(id: 1).actors.find_or_create_by(name: name_actor)
end
