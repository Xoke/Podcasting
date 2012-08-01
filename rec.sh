#!/bin/bash

##################################################
#
#                    LICENSE
#
##################################################
#
# Xoke's Podcasting script.  Records input and encodes it for you.
# Copyright (C) 2010-2012 Xoke
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details <http://www.gnu.org/licenses/>.


##################################################
#
#                    Versions
#
##################################################
#
# Ver	Date		Author	Description
# ------------------------------------------------------------------------------------
# 0.1	May 2010	Xoke	Initial Version
# 0.2	May 2010	Xoke	Added more variables to encode ogg, flac, speex, mp3
#							and allow playback of chosen version
# 0.2.1	May 2010	Xoke	Option to export only recorded section as speex in case
#							you have music on intro and outro
# 0.2.2	May 2010	Xoke	Allows different recording qualities
# 0.2.3 May 2010	Xoke	MP3 files now tagged (simplistically)
# 0.2.4 May 2010	Xoke	Upload enabled (but untested)
# 0.2.4 May 2010	Xoke	New option to change output file
# 0.2.5 Jun 2010	Xoke	Check if file exists and ask what to do (overwrite etc)
#							Assumes you messed up and forgot to have settings, so will
#							process the file as if you just recorded it.
# 0.2.6	Jun 2010	Xoke	Fixed the upload part!
# 0.3	Aug 2010	Xoke	Worked on normalizing everything and tidied up filenames
#							No more -full on filenames!
# 0.3.1	Aug 2010	Xoke	Ogg tags should now work (same as the MP3 ones)
# 0.3.2	Aug 2010	Xoke	Will now playback ALL created files
# 0.3.3	Aug 2010	Xoke	Will now upload ALL created files



##################################################
#
#                    Future?
#
##################################################
#
# Add options to change bitrate and options for encoding?
# Chop the last 1/2 second so you don't hear yourself ctrl+c?
# Speex tags and FLAC tags?
# Use a file to keep record of the track number?
# use a file to hold username and passwords?  Settings?
#	That way you don't lose settings when you get a new version
#	And I don't forget to remove the username and password...
# Quiet version perhaps?


##################################################
#
#                    Packages
#
##################################################
#
# if you are using ubuntu you should use the following line:
# 		sudo apt-get install lame oggenc flac sox speex mp3info normalize-audio
# Other distros will most likely require something similar
# Not all of these are required if you are only creating some of the output files


##################################################
#
#                    Constants
#
##################################################
First_CLP="$1"					# The first command line parameter (i.e. filename)
OutputFile="$1_original.wav"	# Output file name (first command line parameter)
Reprocess=0						# This is used if file exists.  Default to NO
CompleteFile="$1.wav"			# Output wave file with intro and outro
IntroFile="default/intro.wav"	# Intro wave file
OutroFile="default/outro.wav"	# Outro wave file
# If you didn't change the above, these should work
PlaybackFile="$1.flac"			# Playback the flac file
#PlaybackFile="$1.ogg"			# Playback the ogg file
#PlaybackFile=$1.mp3			# Playback the mp3 file
#PlaybackFile=$1.spx			# Playback the speex file with only the recorded section
TagArtist="Xoke"
TagComment="http://xoke.org"
TagGenre="Speech"
TagAlbum="HackerPublicRadio"
TagTrack="XXX"
# shift to remove $1 (filename) and grab the rest as the title
shift
# Title is any other command line parameters
TagTitle="$*"
TagYear=$(date +%Y)							# Use the current year
FTPServerName=ftp.hackerpublicradio.org		# FTP Address
FTPUserName=XXX		# FTP Username
FTPPassword=XXX
FTPDirectory=XXX	# FTP Directory


##################################################
#
#                    Options
#
##################################################
Debug=0							# Show extra debugging output if 1
RecordFormat="wav"				# How to record the input file (wav, raw, au or voc)
RecordQuality="cd"				# Passed to arecord for quality
IntroOutro=0					# Set to 0 if you don't want intro / outro
Normalize=1						# Set to 1 to normalize
WantFlac=1						# Set to 1 to output flac file
WantOgg=0						# Set to 1 to output ogg file
WantMP3=0						# Set to 1 to output mp3 file
WantSpeex=0						# Set to 1 to output speex file (used with WantFullSpeex below)
WantFullSpeex=0					# Set to 0 to output only recorded section of speex, no intro or outro
WantPlayback=1					# Set to 1 to listen to the final version(s)
WantUpload=0					# Set to 1 to auto upload
FlacCompression=3				# 0-8 compression level for Flac (8 is best)
OggCompression=2				# 0-8 compression level for Ogg (10 is best)
MP3Compression=7				# 0-8 compression level for MP3 (0 is best)
SpeexCompression=4				# 0-8 compression level for Speex (10 is best?)


##################################################
#
#                    Main
#
##################################################

# Check if file exists
if [ -e $OutputFile ]; then
	echo "File exists.  Process wave file like you just recorded it?"
	echo "Y, y or just enter for yes.  Anything else for no."
	echo "If you reply no the files WILL be overwritten!"
	read a
	if [[ $a == "Y" || $a == "y" || $a = "" ]]; then
		Reprocess=1
	fi
fi 

# Do we want to reprocess the file (i.e. use a pre-recorded file)
# or just record new.
if [ $Reprocess = "0" ]; then
	# Record the file
	clear
	echo Press CTRL+C to stop recording
	arecord -f $RecordQuality -t $RecordFormat > $OutputFile
else
	echo "Processing file as if you just recorded it"
fi

if [ $Debug = "1" ]; then
	echo "We have output file now"
fi

# If required put in intro and outro
if [ $IntroOutro = "1" ]; then
	sox -S $IntroFile $OutputFile $OutroFile $CompleteFile norm
else
	# Otherwise copy the outputfile as complete file else
	# the encoding gets it wrong
	cp $OutputFile $CompleteFile
fi

if [ $Debug = "1" ]; then
	echo "Intro and Outro if required"
fi

# Normalize the file if required
# --peak normalizes to the loudest part
if [ $Normalize = "1" ]; then
	normalize-audio --peak $CompleteFile
fi

# Convert into flac, ogg and mp3 formats if required
if [ $WantFlac = "1" ]; then
	flac -f -$FlacCompression $CompleteFile
	# Add the filename to the list
	UploadFiles="$First_CLP.flac"
fi

if [ $WantOgg = "1" ]; then
	oggenc -a $TagArtist -c $TagComment -G $TagGenre -l $TagAlbum -N $TagTrack -t "$TagTitle" -d $TagYear -q $OggCompression $CompleteFile
	# Add the filename to the list
	UploadFiles="$UploadFiles $First_CLP.ogg"
fi

if [ $WantMP3 = "1" ]; then
	lame -V $MP3Compression $CompleteFile $First_CLP.mp3
	mp3info $First_CLP.mp3 -a $TagArtist -c $TagComment -g $TagGenre -l $TagAlbum -n $TagTrack -t "$TagTitle" -y $TagYear
	# Add the filename to the list
	UploadFiles="$UploadFiles $First_CLP.mp3"
fi

if [ $WantSpeex = "1" ]; then
	if [ $WantFullSpeex = "1" ]; then
		speexenc --quality $SpeexCompression $CompleteFile $First_CLP.spx
	else
		speexenc --quality $SpeexCompression $OutputFile $First_CLP.spx
	fi
	# Add the filename to the list
	UploadFiles="$UploadFiles $First_CLP.spx"
fi

echo
echo
echo "Created files"

# Listen to the final cut?
if [ $WantPlayback = "1" ]; then
	read -p "Press enter to start playback file"
	if [ $WantFlac = "1" ]; then
		mplayer $First_CLP.flac
	fi
	if [ $WantOgg = "1" ]; then
		mplayer $First_CLP.ogg
	fi
	if [ $WantMP3 = "1" ]; then
		mplayer $First_CLP.mp3
	fi
	if [ $WantSpeex = "1" ]; then
		mplayer $First_CLP.spx
	fi
fi

if [ $Debug = "1" ]; then
	echo "Listened to final cut"
fi

# Upload somewhere?
if [ $WantUpload = "1" ]; then
	if [ $Debug = "1" ]; then
		echo $UploadFiles
	fi
	echo
	echo
	echo About to upload - press CTRL + C to cancel - files will not be deleted
	read -p "Press enter to upload file"
	ftp -inv $FTPServerName <<ENDFTP
	user $FTPUserName $FTPPassword
	cd $FTPDirectory
	mput $UploadFiles
	bye
ENDFTP
fi

if [ $Debug = "1" ]; then
	echo "Completed Upload"
fi
