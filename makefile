STD = std=c++17

#dir
ROOT_DIR = ./
LUA_DIR = /usr/local/include/lua-5.3.5/
MYSQL_DIR = /usr/include/mysql/
THIRD_DIR = ./third/
SRC_DIR = ./libsocket/

socketcore.so:stdafx.o socket.o session.o socketcore.o
		g++ -g -$(STD) -L=/usr/local/lib64 -L=usr/lib64/mysql stdafx.o socket.o session.o socketcore.o \
		/usr/local/lib64/liblua53.a /usr/local/lib/libboost_system.a  -lmysqlclient\
		-fPIC -shared -o socketcore.so

socketcore.o:$(SRC_DIR)socketcore.cpp $(SRC_DIR)stdafx.h $(SRC_DIR)mytimer.hpp $(SRC_DIR)database.hpp
		g++ -c -$(STD) -I$(LUA_DIR) -I$(MYSQL_DIR) -I$(THIRD_DIR)  \
		$(SRC_DIR)socketcore.cpp -fPIC -o socketcore.o

session.o:$(SRC_DIR)session.cpp $(SRC_DIR)session.h $(SRC_DIR)message.hpp
		g++ -c -$(STD) -I$(LUA_DIR) -I$(MYSQL_DIR) -I$(THIRD_DIR) \
		$(SRC_DIR)session.cpp -fPIC -o session.o

socket.o:$(SRC_DIR)socket.cpp $(SRC_DIR)socket.h
		g++ -c -$(STD) -I$(LUA_DIR) -I$(MYSQL_DIR) -I$(THIRD_DIR) \
		$(SRC_DIR)socket.cpp -fPIC -o socket.o

stdafx.o:$(SRC_DIR)stdafx.cpp $(SRC_DIR)stdafx.h
		g++ -c -$(STD) -I$(LUA_DIR) -I$(MYSQL_DIR) -I$(THIRD_DIR) \
		$(SRC_DIR)stdafx.cpp -fPIC -o stdafx.o

clean:
		rm -rf ./*.o socketcore.so