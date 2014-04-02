require 'formula'

class Openssh < Formula
  homepage 'http://www.openssh.com/'
  url 'http://ftp.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-6.6p1.tar.gz'
  version '6.6p1'
  sha256 '48c1f0664b4534875038004cc4f3555b8329c2a81c1df48db5c517800de203bb'

  option 'with-keychain-support', 'Add native OS X Keychain and Launch Daemon support to ssh-agent'

  depends_on 'autoconf' => :build if build.with? 'keychain-support'
  depends_on 'openssl'
  depends_on 'ldns' => :optional
  depends_on 'pkg-config' => :build if build.with? "ldns"

  patch do
    url "https://gist.githubusercontent.com/Bluerise/9400603/raw/28b1cabcc468ce67a41b866eec03032d814a8c18/OpenSSH+6.6p1+keychain+support"
    sha1 "32e6527d7d70b3c0c9a6bd18ddd0b13ed939ea92"
  end if build.with? "keychain-support"

  def install
    system "autoreconf -i" if build.with? 'keychain-support'

    if build.with? "keychain-support"
      ENV.append "CPPFLAGS", "-D__APPLE_LAUNCHD__ -D__APPLE_KEYCHAIN__"
      ENV.append "LDFLAGS", "-framework CoreFoundation -framework SecurityFoundation -framework Security"
    end

    args = %W[
      --with-libedit
      --with-kerberos5
      --prefix=#{prefix}
      --sysconfdir=#{etc}/ssh
      --with-ssl-dir=#{Formula["openssl"].opt_prefix}
    ]

    args << "--with-ldns" if build.with? "ldns"

    system "./configure", *args
    system "make"
    system "make install"
  end

  def caveats
    if build.with? "keychain-support" then <<-EOS.undent
        For complete functionality, please modify:
          /System/Library/LaunchAgents/org.openbsd.ssh-agent.plist

        and change ProgramArguments from
          /usr/bin/ssh-agent
        to
          #{HOMEBREW_PREFIX}/bin/ssh-agent

        After that, you can start storing private key passwords in
        your OS X Keychain.
      EOS
    end
  end
end
