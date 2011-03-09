#import "texture2d.h"
#import <map>
#import <string>
#import <sstream>

class Font {
public:
	Font(const std::string &family = "Helvetica", int size = 36);
	Font(int size, const std::string &family = "Helvetica");
	~Font();
	
	// Prints 'text' at location x, y, z and increases or decreases the size by multiplying with 'scale'.
	//
	// 'text' is UTF-8 so you can use ascii or UTF-8 characters!
	//
	// 'align' to -1 for left align, 0 for center and 1 for right align.
	void print(const std::string &text, GLfloat x, GLfloat y, GLfloat z, int align = -1, GLfloat scale = 1.0f);
	
	struct PrintStream {
		
		PrintStream(Font *font, GLfloat x, GLfloat y, GLfloat z, int align, GLfloat scale);
		PrintStream(const PrintStream &ps);
		~PrintStream();
		
		Font *font;
		std::ostringstream os;
		GLfloat x, y, z;
		int align;
		GLfloat scale;
		
		template <typename T>
		PrintStream &operator<<(const T &t)
		{
			os << t;
			
			return *this;
		}
	};
	
	// Like print above but can be used as a stream.  Example usage:
	// 
	// print(0, 0, 0) << "Hello World.";
	PrintStream print(GLfloat x, GLfloat y, GLfloat z, int align = -1, GLfloat scale = 1.0f);
	
	struct Size { int width, height; };
	
	// Returns the width and height of the given 'text' as it would be drawn.
	Size getSize(const std::string &text, GLfloat scale = 1.0f);
	
private:
	
	struct Char {
		GLuint tex;
		GLuint w, h;
		GLuint tw, th;
	};
	
	// Returns a Char for the given character.  'c' may be in ASCII or UTF-8.
	//
	// If the Char is not yet loaded it will be now.
	//
	// *readCount will be set to the number of characters read from 'c'.  Be sure to increment
	// that many characters forward!
	Char getChar(const char *c, int *readCount);
	
	// UTF-8 encoded character with unused bytes set to 0.
	struct Utf8 {
		char c[6];
		
		Utf8()
		{
			memset(c, 0, 6);
		}
		
		Utf8(const Utf8 &u)
		{
			memcpy(c, u.c, 6);
		}
		
		Utf8 &operator =(const Utf8 &u)
		{
			memcpy(c, u.c, 6);
			
			return *this;
		}
		
		bool operator <(const Utf8 &u) const
		{
			for(int i = 0; i < 6; i++)
				if(c[i] < u.c[i])
					return true;
			
			return false;
		}
		
		bool operator ==(const Utf8 &u) const
		{
			for(int i = 0; i < 6; i++)
				if(c[i] != u.c[i])
					return false;
			
			return true;
		}
	};
	
	// Used to retrieve the UTF-8 value from 'c'.  *readCount is set to the number of characters read from 'c'.
	Utf8 getUtf8(const char *c, int *readCount);
	
	typedef std::map<Utf8, Char> Chars;
	Chars chars;
	
	NSString *family;
	const int size;
};
