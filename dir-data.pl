#!/usr/bin/perl

use Digest::MD5;

# MODE STUFF from https://man7.org/linux/man-pages/man7/inode.7.html
#    The file type and mode
#        The stat.st_mode field (for statx(2), the statx.stx_mode field)
#        contains the file type and mode.
#
#        POSIX refers to the stat.st_mode bits corresponding to the mask
#        S_IFMT (see below) as the file type, the 12 bits corresponding to the
#        mask 07777 as the file mode bits and the least significant 9 bits
#        (0777) as the file permission bits.
#
#        The following mask values are defined for the file type:
#
#            S_IFMT     0170000   bit mask for the file type bit field
#
#            S_IFSOCK   0140000   socket
#            S_IFLNK    0120000   symbolic link
#            S_IFREG    0100000   regular file
#            S_IFBLK    0060000   block device
#            S_IFDIR    0040000   directory
#            S_IFCHR    0020000   character device
#            S_IFIFO    0010000   FIFO
#
#        Thus, to test for a regular file (for example), one could write:
#
#            stat(pathname, &sb);
#            if ((sb.st_mode & S_IFMT) == S_IFREG) {
#                /* Handle regular file */
#            }
#
#        Because tests of the above form are common, additional macros are
#        defined by POSIX to allow the test of the file type in st_mode to be
#        written more concisely:
#
#            S_ISREG(m)  is it a regular file?
#
#            S_ISDIR(m)  directory?
#
#            S_ISCHR(m)  character device?
#
#            S_ISBLK(m)  block device?
#
#            S_ISFIFO(m) FIFO (named pipe)?
#
#            S_ISLNK(m)  symbolic link?  (Not in POSIX.1-1996.)
#
#            S_ISSOCK(m) socket?  (Not in POSIX.1-1996.)
#
#        The preceding code snippet could thus be rewritten as:
#
#            stat(pathname, &sb);
#            if (S_ISREG(sb.st_mode)) {
#                /* Handle regular file */
#            }
#
#        The definitions of most of the above file type test macros are pro‐
#        vided if any of the following feature test macros is defined:
#        _BSD_SOURCE (in glibc 2.19 and earlier), _SVID_SOURCE (in glibc 2.19
#        and earlier), or _DEFAULT_SOURCE (in glibc 2.20 and later).  In addi‐
#        tion, definitions of all of the above macros except S_IFSOCK and
#        S_ISSOCK() are provided if _XOPEN_SOURCE is defined.
#
#        The definition of S_IFSOCK can also be exposed either by defining
#        _XOPEN_SOURCE with a value of 500 or greater or (since glibc 2.24) by
#        defining both _XOPEN_SOURCE and _XOPEN_SOURCE_EXTENDED.
#
#        The definition of S_ISSOCK() is exposed if any of the following fea‐
#        ture test macros is defined: _BSD_SOURCE (in glibc 2.19 and earlier),
#        _DEFAULT_SOURCE (in glibc 2.20 and later), _XOPEN_SOURCE with a value
#        of 500 or greater, _POSIX_C_SOURCE with a value of 200112L or
#        greater, or (since glibc 2.24) by defining both _XOPEN_SOURCE and
#        _XOPEN_SOURCE_EXTENDED.
#
#        The following mask values are defined for the file mode component of
#        the st_mode field:
#
#            S_ISUID     04000   set-user-ID bit (see execve(2))
#            S_ISGID     02000   set-group-ID bit (see below)
#            S_ISVTX     01000   sticky bit (see below)
#
#            S_IRWXU     00700   owner has read, write, and execute permission
#            S_IRUSR     00400   owner has read permission
#            S_IWUSR     00200   owner has write permission
#            S_IXUSR     00100   owner has execute permission
#
#            S_IRWXG     00070   group has read, write, and execute permission
#            S_IRGRP     00040   group has read permission
#            S_IWGRP     00020   group has write permission
#            S_IXGRP     00010   group has execute permission
#
#            S_IRWXO     00007   others (not in group) have read, write, and
#                                execute permission
#            S_IROTH     00004   others have read permission
#            S_IWOTH     00002   others have write permission
#            S_IXOTH     00001   others have execute permission
#
#        The set-group-ID bit (S_ISGID) has several special uses.  For a
#        directory, it indicates that BSD semantics are to be used for that
#        directory: files created there inherit their group ID from the direc‐
#        tory, not from the effective group ID of the creating process, and
#        directories created there will also get the S_ISGID bit set.  For an
#        executable file, the set-group-ID bit causes the effective group ID
#        of a process that executes the file to change as described in
#        execve(2).  For a file that does not have the group execution bit
#        (S_IXGRP) set, the set-group-ID bit indicates mandatory file/record
#        locking.
#
#        The sticky bit (S_ISVTX) on a directory means that a file in that
#        directory can be renamed or deleted only by the owner of the file, by
#        the owner of the directory, and by a privileged process.

sub clean_string {
    my ($s) = @_;
    $s =~ s/\\/\\\\/g;
    $s =~ s/\"/\\\"/g;
    return $s;
}

sub print_file {
    my ($filename) = @_;

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks)
        = stat($filename);

    open (my $fh, '<', $filename) or die "Can't open '$filename': $!";
    binmode ($fh);
    my $md5 = Digest::MD5->new->addfile($fh)->hexdigest;
    close ($fh);

    my $file = clean_string($filename);

    print "{:file \"$file\" :md5 \"$md5\" :mode $mode :size $size :mtime $mtime :ctime $ctime}\n";
}

sub print_link {
    my ($filename) = @_;

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks)
        = lstat($filename);

    my $targetname = readlink $filename;

    my $file = clean_string($filename);
    my $target = clean_string($targetname);

    print "{:link \"$file\" :target \"$target\" :mode $mode :size $size :mtime $mtime :ctime $ctime}\n";
}

sub print_dir {
    my ($filename) = @_;

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks)
        = stat($filename);

    my $file = clean_string($filename);

    print "{:dir \"$file\" :mode $mode :size $size :mtime $mtime :ctime $ctime}\n";
}

sub print_socket {
    my ($filename) = @_;

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks)
        = stat($filename);

    my $file = clean_string($filename);

    print "{:socket \"$file\" :mode $mode :mtime $mtime :ctime $ctime}\n";
}

sub print_pipe {
    my ($filename) = @_;

    my ($dev,$ino,$mode,$nlink,$uid,$gid,$rdev,$size,
        $atime,$mtime,$ctime,$blksize,$blocks)
        = stat($filename);

    my $file = clean_string($filename);

    print "{:pipe \"$file\" :mode $mode :mtime $mtime :ctime $ctime}\n";
}


foreach $f (@ARGV) {
    if (-l $f) {
        print_link ($f);
    }
    elsif (-f $f) {
        print_file ($f);
    }
    elsif (-d $f) {
        print_dir ($f);
    }
    elsif (-S $f) {
        print_socket ($f);
    }
    elsif (-p $f) {
        print_pipe ($f);
    }
    else {
        die "Unknown file type: $f";
    }
}
