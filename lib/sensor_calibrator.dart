class Calibrator {
  double _calibrate(
      double value, double min2, double max2, double min1, double max1) {
    return min1 + ((value - min2) * (max1 - min1)) / (max2 - min2);
  }

  double calibrateAx(double axValue) =>
      _calibrate(axValue, 0.1, 0.13, -0.06, -0.03);
  double calibrateAy(double ayValue) =>
      _calibrate(ayValue, 0.01, 0.03, 0.02, 0.03);
  double calibrateAz(double azValue) =>
      _calibrate(azValue, 0.95, 0.97, 0.98, 1.02);
  double calibrateRx(double rxValue) =>
      _calibrate(rxValue, 0.47, 1.88, 0.89, 1.82);
  double calibrateRy(double ryValue) =>
      _calibrate(ryValue, 6.03, 7.81, -3.6, -1.78);
  double calibrateRz(double rzValue) =>
      _calibrate(rzValue, 72.9, 82.41, -74.05, -51.34);
}
