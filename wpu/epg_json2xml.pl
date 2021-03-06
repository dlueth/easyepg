#!/usr/bin/perl

#      Copyright (C) 2019 Jan-Luca Neumann
#      https://github.com/sunsettrack4/easyepg
#
#      Collaborators:
#      - DeBaschdi ( https://github.com/DeBaschdi )
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 3, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with easyepg. If not, see <http://www.gnu.org/licenses/>.

# ################################
# WAIPU.TV JSON > XML CONVERTER  #
# ################################

# EPG

use strict;
use warnings;
 
binmode STDOUT, ":utf8";
use utf8;
 
use JSON;
use Data::Dumper;
use Time::Piece;
 
# READ JSON INPUT FILE: EPG WORKFILE
my $json;
{
    local $/; #Enable 'slurp' mode
    open my $fh, "<", "workfile" or die;
    $json = <$fh>;
    close $fh;
}

# READ JSON INPUT FILE: ENABLED CHANNELS
my $chidlist;
{
    local $/; #Enable 'slurp' mode
    open my $fh, "<", "/tmp/compare.json" or die;
    $chidlist = <$fh>;
    close $fh;
}

# READ JSON INPUT FILE: RYTEC ID LIST
my $chlist;
{
    local $/; #Enable 'slurp' mode
    open my $fh, "<", "wpu_channels.json" or die;
    $chlist = <$fh>;
    close $fh;
}

# READ JSON INPUT FILE: EIT CATEGORY LIST
my $genrelist;
{
    local $/; #Enable 'slurp' mode
    open my $fh, "<", "wpu_genres.json" or die;
    $genrelist = <$fh>;
    close $fh;
}

# READ INIT FILE
my $init;
{
	local $/; #Enable 'slurp' mode
    open my $fh, '<', "init.json" or die;
    $init = <$fh>;
    close $fh;
}

# READ SETTINGS FILE
my $settings;
{
	local $/; #Enable 'slurp' mode
    open my $fh, '<', "settings.json" or die;
    $settings = <$fh>;
    close $fh;
}
 
# CONVERT JSON TO PERL STRUCTURES
my $data      = decode_json($json);
my $chdata    = decode_json($chlist);
my $chiddata  = decode_json($chidlist);
my $genredata = decode_json($genrelist);
my $initdata  = decode_json($init);
my $setupdata = decode_json($settings);

# DEFINE COUNTRY VERSION
my $countryVER =  $initdata->{'country'};
        
# DEFINE LANGUAGE VERSION
my $languageVER =  $initdata->{'language'};

print "\n<!-- EPG DATA - SOURCE: WAIPU.TV $countryVER -->\n\n";
 
my @attributes = @{ $data->{'attributes'} };
foreach my $item ( @attributes ) {

	my @programs = @{ $item->{'programs'} };
        
    foreach my $programs ( @programs ) {
			
		# ####################
		# DEFINE JSON VALUES #
		# ####################
			
		# DEFINE TIMES AND CHANNEL ID
		my $start    = $programs->{'startTime'};
		my $end      = $programs->{'stopTime'};
		my $cid      = $programs->{'channel'};
			
		# CONVERT FROM TIMESTAMP TO XMLTV DATE FORMAT
		$start =~ s/[-T:]//g;
		$start =~ s/\+/ +/g;
		$end   =~ s/[-T:]//g;
		$end   =~ s/\+/ +/g;
			
		# DEFINE PROGRAM STRINGS
		my $image     = $programs->{'previewImages'}[0];
		my $title     = $programs->{'title'};
		my $subtitle  = $programs->{'episodeTitle'}; 
		my $desc      = $programs->{'description'};
		my @actor     = @{ $programs->{'actors'} };
		my $date      = $programs->{'year'};
		my $country   = $programs->{'country'};
		my $genre     = $programs->{'genreDisplayName'};
		my $series    = $programs->{'season'};
		my $episode   = $programs->{'episode'};
		
		# DEFINE RYTEC CHANNEL ID (language)
		my $rytec = $chdata->{'channels'}{$countryVER};
			
		# DEFINE CHANNEL ID
		my @cidEXT = @{ $chiddata->{'config'} };
		my $new_name2id = $chiddata->{'newname2id'};
			
		# DEFINE EIT GENRES (language)
		my $eit = $genredata->{'categories'}{$countryVER};
			
		# DEFINE SETTINGS
		my $setup_general  = $setupdata->{'settings'};
		my $setup_cid      = $setup_general->{'cid'};
		my $setup_genre    = $setup_general->{'genre'};
		my $setup_category = $setup_general->{'category'};
		my $setup_episode  = $setup_general->{'episode'};  
			
		# DEFINE SETTINGS VALUES
		my $enabled  = "enabled";
		my $disabled = "disabled";
		my $xmltv_ns = "xmltv_ns";
		my $onscreen = "onscreen";
			
		# ##################
		# PRINT XML OUTPUT #
		# ##################
			
		foreach my $cidEXT ( @cidEXT ) {
			
			# PRINT PROGRAMME STRING ONLY IF CERTAIN VALUES ARE DEFINED
			if( defined $title and defined $start and defined $end and defined $cid ) {
					
				my $new_id = $new_name2id->{$cidEXT};
				
				if( defined $new_id ) {
				
					# BEGIN OF PROGRAMME: START / STOP / CHANNEL (condition) (settings)
					if( $new_id eq $cid ) {
						if( $setup_cid eq $enabled ) {
							if( defined $rytec->{$cidEXT} ) {
								print "<programme start=\"$start\" stop=\"$end\" channel=\"" . $rytec->{$cidEXT} . "\">\n";
							} else {
								print "<programme start=\"$start\" stop=\"$end\" channel=\"" . $cidEXT . "\">\n";
								print STDERR "[ EPG WARNING ] Rytec ID not matched for: " . $cidEXT . "\n";
							}
						} else {
							print "<programme start=\"$start\" stop=\"$end\" channel=\"" . $cidEXT . "\">\n";
						}
							
						# IMAGE (condition)
						if( defined $image ) {
							print "  <icon src=\"" . $image . "?width=640&amp;height=380" . "\" />\n";
						}
							
						# TITLE (language)
						$title =~ s/\&/\&amp;/g;
						$title =~ s/<[^>]*>//g;
						$title =~ s/[<>]//g;
						print "  <title lang=\"$languageVER\">$title</title>\n";
								
						# SUBTITLE (condition) (language)
						if( defined $subtitle ) {
							$subtitle =~ s/\&/\&amp;/g;
							$subtitle =~ s/<[^>]*>//g;
							$subtitle =~ s/[<>]//g;
							print "  <sub-title lang=\"$languageVER\">$subtitle</sub-title>\n";
						}
							
						# DESCRIPTION (condition) (language)
						if( defined $desc ) {
							$desc =~ s/\&/\&amp;/g;					# REQUIRED TO READ XML FILE CORRECTLY
							$desc =~ s/<[^>]*>//g;					# REMOVE XML STRINGS WITHIN JSON VALUE
							$desc =~ s/[<>]//g;
							print "  <desc lang=\"$languageVER\">$desc</desc>\n";
						}
							
						# CREDITS (condition)
						if ( @actor ) {
							print "  <credits>\n";
							foreach my $actor ( @actor ) {
								my $PRINTactor = $actor->{'name'};
								$PRINTactor =~ s/\&/\&amp;/g;
								print "    <actor>" . $PRINTactor . "</actor>\n";
							}
							print "  </credits>\n";
						}
							
						# DATE (condition)
						if( defined $date ) {
							$date =~ s/\/.*//g;
							print "  <date>$date</date>\n";
						}
							
						# COUNTRY (condition)
						if( defined $country ) {
							print "  <country>" . $country . "</country>\n";
						}
							
						# CATEGORIES (USE SINGLE CATEGORY) (condition) (language) (settings)
						if ( defined $genre ) {
							$genre =~ s/\&/\&amp;/g;
							if ( $setup_genre eq $enabled ) {
								if ( defined $eit->{ $genre } ) {
									print "  <category lang=\"$languageVER\">" . $eit->{ $genre } . "</category>\n";
								} else {
									print "  <category lang=\"$languageVER\">$genre</category>\n";
									print STDERR "[ EPG WARNING ] CATEGORY UNAVAILABLE IN EIT LIST: " . "$genre" . "\n";;
								}
							} else {
								print "  <category lang=\"$languageVER\">$genre</category>\n";
							}
						}
							
						# SEASON/EPISODE (XMLTV_NS) (condition) (settings)
						if( $setup_episode eq $xmltv_ns ) {
							if( defined $series ) {
								$series =~ s/,.*//g;
								$series =~ s/[A-Za-z]//g;
								my $XMLseries  = $series - 1;
								if( defined $episode ) {
									$episode =~ s/,.*//g;
									$episode =~ s/[A-Za-z]//g;
									my $XMLepisode = $episode - 1;
									print "  <episode-num system=\"xmltv_ns\">$XMLseries . $XMLepisode . </episode-num>\n";
								} else {
									print "  <episode-num system=\"xmltv_ns\">$XMLseries . 0 . </episode-num>\n";
								}
							} elsif( defined $episode ) {
								$episode =~ s/,.*//g;
								$episode =~ s/[A-Za-z]//g;
								my $XMLepisode = $episode - 1;
								print "  <episode-num system=\"xmltv_ns\">0 . $XMLepisode . </episode-num>\n";
							}
						}
						
						# SEASON/EPISODE (ONSCREEN) (condition) (settings)
						if( $setup_episode eq $onscreen ) {
							if( defined $series ) {
								$series =~ s/,.*//g;
								$series =~ s/[A-Za-z]//g;
								if( defined $episode ) {
									$episode =~ s/,.*//g;
									$episode =~ s/[A-Za-z]//g;
									print "  <episode-num system=\"onscreen\">S$series E$episode</episode-num>\n";
								} else {
									print "  <episode-num system=\"onscreen\">S$series</episode-num>\n";
								}
							} elsif( defined $episode ) {
								$episode =~ s/,.*//g;
								$episode =~ s/[A-Za-z]//g;
								print "  <episode-num system=\"onscreen\">E$episode</episode-num>\n";
							}
						}
								
						# END OF PROGRAMME
						print "</programme>\n";
					
					} elsif( not defined $new_id ) {
						print STDERR "[ EPG WARNING ] $cidEXT not found in new channel list!\n";
					}
				}
			}
		}
    }
}
