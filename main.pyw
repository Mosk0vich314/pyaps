"""
Entry point for PYAPS.
Run with: python main.py
"""

import sys
from PySide6.QtCore import QLocale
from PySide6.QtWidgets import QApplication
from gui.main_window import MainWindow


def main():
    # Force C locale so QDoubleSpinBox always accepts '.' as decimal separator
    # (regardless of system locale, e.g. Italian which expects ',').
    QLocale.setDefault(QLocale(QLocale.C))
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    window = MainWindow()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
