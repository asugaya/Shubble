#include "cinder/Cinder.h"
#include "cinder/app/AppCocoaTouch.h"
#include "cinder/app/AppNative.h"
#include "cinder/app/Renderer.h"
#include "cinder/Surface.h"
#include "cinder/gl/Texture.h"
#include "cinder/Camera.h"
#include "cinder/app/AppBasic.h"
#include "cinder/Text.h"
#include "cinder/ImageIo.h"
#include "cinder/gl/gl.h"
#include "cinder/gl/Texture.h"
#include "cinder/app/TouchEvent.h"
#include "cinder/Font.h"
#include "SocketTestViewController.h"

#if defined( CINDER_COCOA_TOUCH )
	#include "cinder/app/AppCocoaTouch.h"
	typedef ci::app::AppCocoaTouch AppBase;
#else
	#include "cinder/app/AppBasic.h"
	#include "cinder/audio/FftProcessor.h"
	typedef ci::app::AppBasic AppBase;
#endif

#include "cinder/audio/Input.h"
#include <iostream>
#include <vector>

using namespace ci;
using namespace ci::app;

gl::Texture	mTexture;
int mode;
int connected;
int timerGuy;

int deBounced;
int zeroCounter;
float timer1;
float timer2;
int peakNum;
int diffTime;

class AudioInputSampleApp : public AppBase {
 public:
	void setup();
	void update();
	void draw();
	void drawWaveForm( float height );
    

#if defined(CINDER_MAC)
	void drawFft();
#endif
	
	audio::Input mInput;
	std::shared_ptr<float> mFftDataRef;
	audio::PcmBuffer32fRef mPcmBuffer;
};

void AudioInputSampleApp::setup()
{
	//iterate input devices and print their names to the console
    mode = 0;
    connected=0;
    deBounced=1;
    zeroCounter=0;
    peakNum=0;
	const std::vector<audio::InputDeviceRef>& devices = audio::Input::getDevices();
	for( std::vector<audio::InputDeviceRef>::const_iterator iter = devices.begin(); iter != devices.end(); ++iter ) {
		console() << (*iter)->getName() << std::endl;
	}

	//initialize the audio Input, using the default input device
	mInput = audio::Input();
	
	//tell the input to start capturing audio
	mInput.start();
	
}

void AudioInputSampleApp::update()
{
	mPcmBuffer = mInput.getPcmBuffer();
	if( ! mPcmBuffer ) {
		return;
	}
#if defined( CINDER_MAC )
	uint16_t bandCount = 512;
	//presently FFT only works on OS X, not iOS
	mFftDataRef = audio::calculateFft( mPcmBuffer->getChannelData( audio::CHANNEL_FRONT_LEFT ), bandCount );
#endif
}

void AudioInputSampleApp::draw()
{
#if defined( CINDER_COCOA_TOUCH )
	float waveFormHeight = getWindowWidth() / 2;
#else
	float waveFormHeight = 100.0;
#endif

	gl::setMatricesWindow( getWindowWidth(), getWindowHeight() );
    if(mode == 0 || mode == 1){
        gl::clear( Color( 0.0f, 0.0f, 0.0f ) );
    }else if(mode == 2){
        gl::clear( Color( 0.0f, 0.8f, 0.0f ) );
    }
	
	glPushMatrix();
		drawWaveForm( waveFormHeight );
#if defined(CINDER_MAC)
		glTranslatef( 0.0f, 200.0f, 0.0f );
		drawFft();
#endif
	glPopMatrix();
    
     //console() << mode << std::endl;
    if(mode == 0){ //say waiting for sound
        connected=0;
        TextLayout layout;
        layout.clear(ColorA( 0.0f, 0.0f, 0.0f, 0.0f ) );
        layout.setFont( Font( "HelveticaNeue", 89 ) );
        layout.setColor( ColorA( 1.0f, 1.0f, 1.0f, 1.0f  ) );
        layout.addCenteredLine( std::string( "Shubble" ));
        layout.setFont( Font( "Arial", 48 ) );
        layout.setColor( ColorA( 1.0f, 1.0f, 1.0f, 1.0f  ) );
        layout.addCenteredLine( std::string( "Knock to Set group" ));
        
        layout.setColor( ColorA( 1.0f, 1.0f, 1.0f, 1.0f  ) );
        Surface8u rendered = layout.render( true, false );
        mTexture = gl::Texture( rendered );
        gl::draw( mTexture, Vec2f( 150,400 ) );
    }else if (mode == 1){ //say connecting
        TextLayout layout;
        layout.clear(ColorA( 0.0f, 0.8f, 0.0f, 0.0f ) );
        layout.setFont( Font( "HelveticaNeue", 89 ) );
        layout.setColor( ColorA( 1.0f, 1.0f, 1.0f, 1.0f  ) );
        layout.addCenteredLine( std::string( "Connecting" ));
        layout.setFont( Font( "Arial", 48 ) );
        layout.setColor( ColorA( 1.0f, 1.0f, 1.0f, 1.0f  ) );
        layout.addCenteredLine( std::string( "Knock to Set group" ));
        layout.setColor( ColorA( 1.0f, 1.0f, 1.0f, 1.0f  ) );
        Surface8u rendered = layout.render( true, false );
        mTexture = gl::Texture( rendered );
        gl::draw( mTexture, Vec2f( 150,400 ) );
        
    }else{
        TextLayout layout;
        layout.clear(ColorA( 0.0f, 0.8f, 0.0f, 1.0f ) );
        layout.setFont( Font( "HelveticaNeue", 89 ) );
        layout.setColor( ColorA( 1.0f, 1.0f, 1.0f, 1.0f  ) );
        layout.addCenteredLine( std::string( "Connected" ));
        layout.setFont( Font( "Arial", 48 ) );
        layout.setColor( ColorA( 1.0f, 1.0f, 1.0f, 1.0f  ) );
        layout.addCenteredLine( std::string( "Share Away" ));
        layout.setColor( ColorA( 1.0f, 1.0f, 1.0f, 1.0f  ) );
        Surface8u rendered = layout.render( true, false );
        mTexture = gl::Texture( rendered );
        gl::draw( mTexture, Vec2f( 150,400 ) );
        
        if(connected==0){
            SocketTestViewController *viewController = [[SocketTestViewController alloc] initWithTime:diffTime];
//             SocketTestViewController *viewController = [[SocketTestViewController alloc] init];
            connected=1;
            mode = 0;
            
        }
        
//        NSURL *url = [NSURL URLWithString:@"http://www.stackoverflow.com"];
//        if( ![[UIApplication sharedApplication] openURL:url] )
//            NSLog(@"%@%@",@"Failed to open url:",[url description]);

    }
    

}

void AudioInputSampleApp::drawWaveForm( float height )
{
	if( ! mPcmBuffer ) {
		return;
	}
	
       
	uint32_t bufferSamples = mPcmBuffer->getSampleCount();
	audio::Buffer32fRef leftBuffer = mPcmBuffer->getChannelData( audio::CHANNEL_FRONT_LEFT );
	//audio::Buffer32fRef rightBuffer = mPcmBuffer->getChannelData( audio::CHANNEL_FRONT_RIGHT );

	int displaySize = getWindowWidth();
	int endIdx = bufferSamples;
	
	//only draw the last 1024 samples or less
	int32_t startIdx = ( endIdx - 1024 );
	startIdx = math<int32_t>::clamp( startIdx, 0, endIdx );
	
	float scale = displaySize / (float)( endIdx - startIdx );
	
	PolyLine<Vec2f>	line;
	
	gl::color( Color( 1.0f, 1.0f, 1.0f ) );
	for( uint32_t i = startIdx, c = 0; i < endIdx; i++, c++ ) {
		float y = ( ( leftBuffer->mData[i] - 1 ) * - 100 );
		line.push_back( Vec2f( ( c * scale ), y ) );
        
//        if(y < 70){
//            console() << "Woah" << std::endl;
//            console() << y << std::endl;
//            if(mode == 0){
//                timerGuy = (int)(getElapsedSeconds());
//            }
//            mode = 1;
//            
//        }

        
        if(y < 70){
            if(deBounced==1 && peakNum==0){
                deBounced=0;
                timer1 = getElapsedSeconds();
                timerGuy = (int)(getElapsedSeconds());
                peakNum=1;
            }else if(deBounced==1 && peakNum==1){
                deBounced=0;
                peakNum=0;
                timer2 = getElapsedSeconds();
                mode = 1;
                diffTime = (int)(100*timer2-100*timer1);
                console() << "DiffTime:" << std::endl;
                console() << (int)(100*timer2-100*timer1) << std::endl;
                console() << "---------:" << std::endl;
            }
        }
        
        if(deBounced ==0 && y>100){
            zeroCounter++;
            
        }
        if(zeroCounter==2000){
            console() << "zerocounter:" << std::endl;
            console() << zeroCounter << std::endl;
            deBounced=1;
            zeroCounter=0;
        }
        
        
        
//            console() << "Woah" << std::endl;
//            console() << y << std::endl;
        

        
        
        if(mode == 1 && (int)(getElapsedSeconds()) - timerGuy > 0){
            mode = 2;
        }
        
	}
	gl::draw( line );
	

}

#if defined(CINDER_MAC)
void AudioInputSampleApp::drawFft()
{
	uint16_t bandCount = 512;
	float ht = 1000.0f;
	float bottom = 150.0f;
	
	if( ! mFftDataRef ) {
		return;
	}
	
	float * fftBuffer = mFftDataRef.get();
	
	for( int i = 0; i < ( bandCount ); i++ ) {
		float barY = fftBuffer[i] / bandCount * ht;
		
            glBegin( GL_QUADS );
                glColor3f( 255.0f, 0.0f, 0.0f );
                glVertex2f( i * 3, bottom );
                glVertex2f( i * 3 + 1, bottom );
                glColor3f( 255.0f, 0.0f, 0.0f );
                glVertex2f( i * 3 + 1, bottom - barY );
                glVertex2f( i * 3, bottom - barY );
            glEnd();

        
	}
}
#endif

#if defined( CINDER_COCOA_TOUCH )
CINDER_APP_COCOA_TOUCH( AudioInputSampleApp, RendererGl )
#else
CINDER_APP_BASIC( AudioInputSampleApp, RendererGl )
#endif
