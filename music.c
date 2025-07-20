#include <stdio.h>

unsigned char * reality_fc_data = NULL;
unsigned int reality_fc_datalength = 0;
const char * reality_fc_path = "REALITY.FC";

char load_music()
{
  FILE * f = fopen( reality_fc_path, "rb" );
  if ( !f )
  {
    return 0;
  }
  fseek( f, 0L, SEEK_END );
  reality_fc_datalength = ftell( f );
  reality_fc_data = (unsigned char *)malloc( reality_fc_datalength );
  fseek( f, 0L, SEEK_SET );
  fread( reality_fc_data, (size_t)reality_fc_datalength, 1, f );
  fclose( f );

  return 1;
}

void start_music( int song_idx, int start_order )
{
  unsigned int offset = ( (unsigned int *)reality_fc_data )[ song_idx ];
  st3play_PlaySong( reality_fc_data + offset, reality_fc_datalength, 1, 44100, start_order );
#ifdef _DEBUG
  st3play_SetMasterVol( 100 );
#endif // _DEBUG
}

void end_music()
{
  st3play_Close();

  free( reality_fc_data );
  reality_fc_data = NULL;
}