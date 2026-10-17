# Компилятор и флаги
FPC      = fpc
FPCFLAGS = -Mobjfpc -Sh -O2 -FEbin/

# Основной файл и итоговый бинарник
MAIN     = PkgDependsGraf.pas
TARGET   = PkgDependsGraf

MODULES  = ParseConfig.pp

all: $(TARGET)

$(TARGET): $(MAIN) $(MODULES)
	$(FPC) $(FPCFLAGS) $(MAIN)

clean:
	rm -f bin/*.ppu bin/*.o bin/$(TARGET)

clean-obj:
	rm -f bin/*.ppu bin/*.o

.PHONY: all clean clean-obj
