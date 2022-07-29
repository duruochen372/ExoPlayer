package com.google.android.exoplayer2.demo;

import android.graphics.SurfaceTexture;
import android.os.Bundle;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RelativeLayout;
import android.widget.Toast;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AppCompatActivity;
import com.google.android.exoplayer2.DeviceInfo;
import com.google.android.exoplayer2.ExoPlayer;
import com.google.android.exoplayer2.MediaItem;
import com.google.android.exoplayer2.MediaMetadata;
import com.google.android.exoplayer2.PlaybackException;
import com.google.android.exoplayer2.PlaybackParameters;
import com.google.android.exoplayer2.Player;
import com.google.android.exoplayer2.Timeline;
import com.google.android.exoplayer2.TracksInfo;
import com.google.android.exoplayer2.audio.AudioAttributes;
import com.google.android.exoplayer2.metadata.Metadata;
import com.google.android.exoplayer2.source.TrackGroupArray;
import com.google.android.exoplayer2.text.Cue;
import com.google.android.exoplayer2.trackselection.TrackSelectionArray;
import com.google.android.exoplayer2.trackselection.TrackSelectionParameters;
import com.google.android.exoplayer2.ui.StyledPlayerView;
import com.google.android.exoplayer2.util.Log;
import com.google.android.exoplayer2.video.VideoSize;
import java.util.List;

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

  private String mPlayUrl = "http://live.test.tx.l1.xmcdn.com/live/838707-1043017.flv";

  private TextureView mTextureView;
  private RelativeLayout.LayoutParams small =  new RelativeLayout.LayoutParams(500, 500);
  private RelativeLayout.LayoutParams large = new RelativeLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
  private boolean isSmall = false;
  private boolean isStart = true;

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_video);
    mPlayerView = findViewById(R.id.player_view);
    mTextureView = new TextureView(this);


    RelativeLayout rootView = findViewById(R.id.video_root_fl);
    rootView.addView(mTextureView, small);

    mExoPlayer = new ExoPlayer.Builder(this).build();
//    mPlayerView.setPlayer(mExoPlayer);
    MediaItem mediaItem = MediaItem.fromUri(mPlayUrl);
// Set the media item to be played.
    mExoPlayer.setMediaItem(mediaItem);
// Prepare the player.
    mExoPlayer.prepare();
// Start the playback.
    mExoPlayer.play();
    mExoPlayer.setVideoTextureView(mTextureView);

    findViewById(R.id.video_size_btn).setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        mTextureView.setLayoutParams(isSmall ? large : small);

        isSmall = !isSmall;
      }
    });

    findViewById(R.id.video_pause_btn).setOnClickListener(new View.OnClickListener() {
      @Override
      public void onClick(View v) {
        if (isStart) {
          mExoPlayer.pause();
        } else {
          mExoPlayer.play();
        }
        isStart = !isStart;
      }
    });




    mExoPlayer.addListener(new Player.Listener() {

      @Override
      public void onPlaybackStateChanged(@Player.State int playbackState) {
        switch (playbackState) {
           case Player.STATE_BUFFERING:
             Log.d("duruochen", "开始缓冲");
             break;
          case Player.STATE_READY:
            Log.d("duruochen", "结束缓冲   缓冲区大小:" + mExoPlayer.getTotalBufferedDuration());
            break;
        }
      }


      @Override
      public void onPlayerError(PlaybackException error) {

        Toast.makeText(TestActivity.this, "播放失败", Toast.LENGTH_SHORT).show();
      }

      @Override
      public void onPlayerErrorChanged(@Nullable PlaybackException error) {

      }

      @Override
      public void onVideoSizeChanged(VideoSize videoSize) {
        Log.d("duruochen", "onVideoSizeChanged:width=" + videoSize.width + "   height=" + videoSize.height);
        mTextureView.post(new Runnable() {
          @Override
          public void run() {
            mTextureView.getLayoutParams().width = videoSize.width;
            mTextureView.getLayoutParams().height = videoSize.height;
            mTextureView.requestLayout();
          }
        });

      }
    });

  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    if (mExoPlayer != null) {
      mExoPlayer.release();
    }
  }
}
