Usage
-----

Run the script with -h to see usage info.

How to setup
------------

* Download and extract the official IJG source http://www.ijg.org/files/jpegsrc.v9b.tar.gz

* Download and extract the "drop" patch http://jpegclub.org/droppatch.v9b.tar.gz

* In the patch archive ignore the precompiled executable (the diff is small enough it is worth auditing the changes and compiling yourself, for peace of mind)

* For each source file from the droppatch archive, diff it against its respective file from the official archive (visually check the changes looks sane)

* Copy the droppatch files over their respective files from the official archive

* Enter the official source directory, do: "./configure", "make", "make test", optionally "make install" if you don't want to run it locally to the directory (you could do "make -n install" first to see where the files would end up)

* Then either run this script from within that directory or use the -e flag to specify where the jpegtran executable is, relative to current working directory
