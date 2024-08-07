class Proj < Formula
  desc "Cartographic Projections Library"
  homepage "https://proj.org/"
  url "https://github.com/OSGeo/PROJ/releases/download/9.2.1/proj-9.2.1.tar.gz"
  sha256 "15ebf4afa8744b9e6fccb5d571fc9f338dc3adcf99907d9e62d1af815d4971a1"
  license "MIT"
  head "https://github.com/OSGeo/proj.git", branch: "master"

  bottle do
    sha256 arm64_ventura:  "5ca270dab6620ba02931ff138dcbdb4abca7bc20d697db326ad938b9196bcc48"
    sha256 arm64_monterey: "a17d8684fdb83f30b15af8613e616a78aa606fcded326b180c357b090c8853e8"
    sha256 arm64_big_sur:  "3e10291aa7dfbe56d2f461f9e3c39584148fbb5b6e1c969a3fc88e1b08077169"
    sha256 ventura:        "6e6a57511fcef9272f5a3ae34a40ca16407f7b987ebfa9ad9162a29480cc3a13"
    sha256 monterey:       "45300f1502a03c79da7469f1def7f401348fee0ff1af82d177846f0266569151"
    sha256 big_sur:        "8283a4e41247e94d6b9492c852525f6938534e62b593673ce3a05bbc5a4d6b33"
    sha256 x86_64_linux:   "6d303c7a90b09bf5e174e77ba45c6e3e970e015e7f00405961d54a282af82ece"
  end

  depends_on "cmake" => :build
  depends_on "libtool" => :build
  depends_on "pkg-config" => :build
  depends_on "libtiff"

  uses_from_macos "curl"
  uses_from_macos "sqlite"

  conflicts_with "blast", because: "both install a `libproj.a` library"

  skip_clean :la

  # The datum grid files are required to support datum shifting
  resource "proj-data" do
    url "https://download.osgeo.org/proj/proj-data-1.14.tar.gz"
    sha256 "b5fecececed91f4ba59ec5fc5f5834ee491ee9ab8b67bd7bbad4aed5f542b414"
  end

  def install
    system "cmake", "-S", ".", "-B", "build", *std_cmake_args, "-DCMAKE_INSTALL_RPATH=#{rpath}"
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
    system "cmake", "-S", ".", "-B", "static", *std_cmake_args, "-DBUILD_SHARED_LIBS=OFF"
    system "cmake", "--build", "static"
    lib.install Dir["static/lib/*.a"]
    resource("proj-data").stage do
      cp_r Dir["*"], pkgshare
    end
  end

  test do
    (testpath/"test").write <<~EOS
      45d15n 71d07w Boston, United States
      40d40n 73d58w New York, United States
      48d51n 2d20e Paris, France
      51d30n 7'w London, England
    EOS
    match = <<~EOS
      -4887590.49\t7317961.48 Boston, United States
      -5542524.55\t6982689.05 New York, United States
      171224.94\t5415352.81 Paris, France
      -8101.66\t5707500.23 London, England
    EOS

    output = shell_output("#{bin}/proj +proj=poly +ellps=clrk66 -r #{testpath}/test")
    assert_equal match, output
  end
end
