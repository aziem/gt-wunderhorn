clear
echo "Starting...>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
echo ">>> clean .dot and .ps files"
rm *ps
rm *dot
echo ">>> Compiling"
javac -d bin -sourcepath src src/safetyTester/whiletest/Tester1.java -cp ./bin:./lib/* 
echo ">>> Executing"
java -cp ./bin:./lib/* safetyTester.whiletest.Tester1
echo ">>> creating .ps files"
python PngCreator.py
echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>> Ended ..."