package com.google.android.exoplayer2.demo;

import android.os.Bundle;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.ui.StyledPlayerView;

/**
 * 类的大体描述放在这里。
 *
 * @author duruochen
 * @email eric.du@ximalaya.com
 * @phoneNumber 18817870952
 * @wiki Wiki网址放在这里
 * @server 服务端开发人员放在这里
 * @since 2022/6/15
 */
public class TestActivity extends AppCompatActivity {

  private StyledPlayerView mPlayerView;

  private ExoPlayer mExoPlayer;

  private String mPlayUrl = "http://live.tx.l1.xmcdn.com/live/3249654-16774882.flv?txSecret=53b7bb6476ae65bc35d571e442ce11e8&txTime=62AB037A";



  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_video);
    mPlayerView = findViewById(R.id.player_view);

    mExoPlayer = new ExoPlayer.Builder(this).build();
    mPlayerView.setPlayer(mExoPlayer);
    MediaItem mediaItem = MediaItem.fromUri(mPlayUrl);
// Set the media item to be played.
    mExoPlayer.setMediaItem(mediaItem);
// Prepare the player.
    mExoPlayer.prepare();
// Start the playback.
    mExoPlayer.play();
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    if (mExoPlayer != null) {
      mExoPlayer.release();
    }
  }
}
