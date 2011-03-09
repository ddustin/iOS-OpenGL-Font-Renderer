#import "font.h"
#import <iostream>
#import <string>
using namespace std;

Font::Font(const string &family, int size)
: size(size)
{
	this->family = [[NSString alloc] initWithCString:family.c_str()
											encoding:NSUTF8StringEncoding];
}

Font::Font(int size, const string &family)
: size(size)
{
	this->family = [[NSString alloc] initWithCString:family.c_str()
											encoding:NSUTF8StringEncoding];
}

Font::~Font()
{
	//cout << "Cleaning up chars, size: " << chars.size() << endl;
	chars.clear();
}

Font::PrintStream::PrintStream(Font *font, GLfloat x, GLfloat y, GLfloat z, int align, GLfloat scale)
: font(font), x(x), y(y), z(z), align(align), scale(scale)
{
	
}

Font::PrintStream::PrintStream(const PrintStream &ps)
: font(ps.font), x(ps.x), y(ps.y), z(ps.z), align(ps.align), scale(ps.scale)
{
	
}

Font::PrintStream::~PrintStream()
{
	if(os.tellp())
		font->print(os.str(), x, y, z, align, scale);
}

static const float zero = 0.006f;
static const float one = 0.994f;

// helper function to draw a rectangle
static void setRectData(GLfloat x, GLfloat y, GLfloat z, GLfloat w, GLfloat h, 
						GLfloat *vert, GLfloat *tex, GLfloat *norm, GLfloat wtex = one, GLfloat htex = one,
						GLfloat xstart = zero, GLfloat ystart = zero)
{
	for(int i = 0; i < 18; i += 3) {
		
		norm[i + 0] = 0.0f;
		norm[i + 1] = 0.0f;
		norm[i + 2] = -1.0f;
	}
	
	int i = 0;
	
	wtex += xstart;
	htex += ystart;
	
	vert[i + 0] = x;
	vert[i + 1] = y;
	vert[i + 2] = z;
	
	vert[i + 3] = x;
	vert[i + 4] = y + h;
	vert[i + 5] = z;
	
	vert[i + 6] = x + w;
	vert[i + 7] = y + h;
	vert[i + 8] = z;
	
	tex[i + 0] = xstart;
	tex[i + 1] = ystart;
	tex[i + 2] = zero;
	
	tex[i + 3] = xstart;
	tex[i + 4] = htex;
	tex[i + 5] = zero;
	
	tex[i + 6] = wtex;
	tex[i + 7] = htex;
	tex[i + 8] = zero;
	
	i += 9;
	
	vert[i + 0] = x;
	vert[i + 1] = y;
	vert[i + 2] = z;
	
	vert[i + 3] = x + w;
	vert[i + 4] = y + h;
	vert[i + 5] = z;
	
	vert[i + 6] = x + w;
	vert[i + 7] = y;
	vert[i + 8] = z;
	
	tex[i + 0] = xstart;
	tex[i + 1] = ystart;
	tex[i + 2] = zero;
	
	tex[i + 3] = wtex;
	tex[i + 4] = htex;
	tex[i + 5] = zero;
	
	tex[i + 6] = wtex;
	tex[i + 7] = ystart;
	tex[i + 8] = zero;
}

//static bool loadingIt = true;

void Font::print(const string &text, GLfloat x, GLfloat y, GLfloat z, int align, GLfloat scale)
{
	GLfloat vert[18];
	GLfloat  tex[18];
	GLfloat norm[18];
	
	// getSize() is an expensive operation, so we use sizeDirty.
	Size size;
	bool sizeDirty = true;
	
	if(align > -1) {
		
		if(sizeDirty)
			size = getSize(text, scale);
		
		sizeDirty = false;
		
		if(align > 0)
			x -= size.width;
		else
			x -= size.width / 2;
	}
	
	for(int i = 0, count = 0; i < text.size(); i += count) {
		
		Char c = getChar(text.c_str() + i, &count);
		
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glEnableClientState(GL_NORMAL_ARRAY);
		
		setRectData(x, y, z, c.w * scale, c.h * scale, vert, tex, norm, GLfloat(c.w) / c.tw, GLfloat(c.h) / c.th);
		
		glVertexPointer(3, GL_FLOAT, 0, vert);
		glTexCoordPointer(3, GL_FLOAT, 0, tex);
		glNormalPointer(GL_FLOAT, 0, norm);
		
		glBindTexture(GL_TEXTURE_2D, c.tex);
		
		glDrawArrays(GL_TRIANGLES, 0, 6);
		
		x += c.w * scale;
	}
	
	//loadingIt = false;
}

Font::PrintStream Font::print(GLfloat x, GLfloat y, GLfloat z, int align, GLfloat scale)
{
	return PrintStream(this, x, y, z, align, scale);
}

Font::Size Font::getSize(const std::string &text, GLfloat scale)
{
	CGSize stringSize = [[[NSString alloc] initWithUTF8String:text.c_str()] sizeWithFont:[UIFont fontWithName:family size:size]];
	
	Size s = { stringSize.width * scale, stringSize.height * scale };
	
	return s;
}

Font::Char Font::getChar(const char *c, int *readCount)
{
	Utf8 u = getUtf8(c, readCount);
	
	Chars::iterator loc = chars.find(u);
	
	if(loc != chars.end())
		return loc->second;
	
	//if(loadingIt)
		//cout << "Loading a character...\n";
	
	Char ret;
	
	string tmp(u.c, *readCount);
	
	NSString *str = [[NSString alloc] initWithUTF8String:tmp.c_str()];
	
	CGSize stringSize = [str sizeWithFont:[UIFont fontWithName:family size:size]];
	
	//stringSize.width = 32;
	//stringSize.height = 32;
	
	// Set up texture
	Texture2D* statusTexture = [[Texture2D alloc] initWithString:str dimensions:CGSizeMake(stringSize.width, stringSize.height)
									alignment:UITextAlignmentLeft fontName:family fontSize:size];
	
	ret.tex = [statusTexture name];
	ret.w = stringSize.width;
	ret.h = stringSize.height;
	ret.tw = statusTexture->_width;
	ret.th = statusTexture->_height;
	
	//cout << "(" << string(u.c, *readCount) << ") w:" << ret.w << ", h:" << ret.h << endl;
	
	chars.insert(make_pair(u, ret));
	
	//for(Chars::iterator itr = chars.begin(); itr != chars.end(); ++itr)
		//cout << "[" << itr->second.tex << "] ";
	
	//cout << endl;
	
	return ret;
}

Font::Utf8 Font::getUtf8(const char *c, int *readCount)
{
	Utf8 ret;
	
	*readCount = 0;
	
	for(int i = 7; i > 0; --i)
		if(*c & (1 << i))
			++*readCount;
		else
			break;
	
	if(!*readCount)
		*readCount = 1;
	
	memcpy(ret.c, c, *readCount);
	/*
	if(loadingIt) {
		
		cout << "Looking at c(" << string(c, *readCount) << ") for " << *readCount << " len, Result:";
		
		for(int i = 0; i < 6; i++)
			cout << " [" << i << "]:" << (int)ret.c[i];
		
		cout << endl;
	}
	*/
	return ret;
}
