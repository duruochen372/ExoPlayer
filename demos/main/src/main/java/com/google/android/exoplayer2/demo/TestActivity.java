package com.google.android.exoplayer2.demo;

import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.SurfaceTexture;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
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
import java.util.Timer;
import java.util.TimerTask;

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

  private String TAG = "TestActivity";

//  private String mPlayUrl = "http://live.test.tx.l1.xmcdn.com/live/284707-1046357_translow.flv";  //个人直播
//  private String mPlayUrl = "http://live.test.xmc.tx.l1.xmcdn.com/live/3-2-842650-765008-317012.flv"; //obs推流
//  private String mPlayUrl = "http://live.test.tx.l1.xmcdn.com/live/838707-1049699.flv?txSecret=2102f8e4c6492984897b61e29e2bcbf6&txTime=631330E2&liveType=2&token=a5728eda9c2843a0a83926f64184ffec&txDelayTime=7&userId=1173284";

  private String mPlayUrl = "http://live.tx.l1.xmcdn.com/live/6350975-22838614.flv";


  private TextureView mTextureView;
  private SurfaceView mSurfaceView;
  private ImageView mIv;
  private RelativeLayout.LayoutParams small =  new RelativeLayout.LayoutParams(500, 500);
  private RelativeLayout.LayoutParams large = new RelativeLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.MATCH_PARENT);
  private boolean isSmall = false;
  private boolean isStart = true;

  private Handler mHandler;

  @Override
  protected void onCreate(@Nullable Bundle savedInstanceState) {
    super.onCreate(savedInstanceState);
    setContentView(R.layout.activity_video);
    mPlayerView = findViewById(R.id.player_view);
    mTextureView = new TextureView(this);
    mSurfaceView = new SurfaceView(this);
    mIv = findViewById(R.id.image);

    mHandler = new Handler(Looper.getMainLooper());

//    Log.d("duruochen", "manifest_string=" + manifest_string);


    RelativeLayout rootView = findViewById(R.id.video_root_fl);
    rootView.addView(mSurfaceView, large);

    mExoPlayer = new ExoPlayer.Builder(this).build();
//    mPlayerView.setPlayer(mExoPlayer);
    MediaItem mediaItem = MediaItem.fromUri(mPlayUrl);
// Set the media item to be played.
    mExoPlayer.setMediaItem(mediaItem);
// Prepare the player.
    mExoPlayer.prepare();
// Start the playback.
    mExoPlayer.play();
    mSurfaceView.getHolder().addCallback(new SurfaceHolder.Callback() {
      @Override
      public void surfaceCreated(@NonNull SurfaceHolder holder) {
        mExoPlayer.setVideoSurfaceView(mSurfaceView);
      }

      @Override
      public void surfaceChanged(@NonNull SurfaceHolder holder, int format, int width, int height) {

      }

      @Override
      public void surfaceDestroyed(@NonNull SurfaceHolder holder) {

      }
    });

    Log.d("duruochen111", "aaa");
    mHandler.postDelayed(new Runnable() {
      @Override
      public void run() {
        rootView.addView(mTextureView, large);


//        mSurfaceView.getHolder().addCallback(new SurfaceHolder.Callback() {
//          @Override
//          public void surfaceCreated(@NonNull SurfaceHolder holder) {
//            mExoPlayer.setVideoSurfaceView(mSurfaceView);
//          }
//
//          @Override
//          public void surfaceChanged(@NonNull SurfaceHolder holder, int format, int width,
//              int height) {
//
//          }
//
//          @Override
//          public void surfaceDestroyed(@NonNull SurfaceHolder holder) {
//
//          }
//        });
      }
    }, 10000);

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
          mExoPlayer.stop();
        } else {
          MediaItem mediaItem = MediaItem.fromUri(mPlayUrl);
          mExoPlayer.setMediaItem(mediaItem);
          mExoPlayer.prepare();
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
             Log.d(TAG, "开始缓冲");
             break;
          case Player.STATE_READY:
            Log.d(TAG, "STATE_READY   缓冲区大小:" + mExoPlayer.getTotalBufferedDuration());
            break;
        }
      }


      @Override
      public void onPlayerError(PlaybackException error) {

        Log.d("duruochen", "播放失败:" + error + "   " + android.util.Log.getStackTraceString(new Throwable()));
        Toast.makeText(TestActivity.this, "播放失败", Toast.LENGTH_SHORT).show();
      }

      @Override
      public void onPlayerErrorChanged(@Nullable PlaybackException error) {

      }

      @Override
      public void onVideoSizeChanged(VideoSize videoSize) {
        Log.d(TAG, "onVideoSizeChanged:width=" + videoSize.width + "   height=" + videoSize.height);
        mHandler.post(new Runnable() {
          @Override
          public void run() {
            if (mTextureView != null && mTextureView.getLayoutParams() != null) {
              mTextureView.getLayoutParams().width = videoSize.width;
              mTextureView.getLayoutParams().height = videoSize.height;
              mTextureView.requestLayout();
            }

            mSurfaceView.getLayoutParams().width = videoSize.width;
            mSurfaceView.getLayoutParams().height = videoSize.height;
            mSurfaceView.requestLayout();
          }
        });

      }

      @Override
      public void onRenderedFirstFrame() {
        Log.d(TAG, "onRenderedFirstFrame");
        Player.Listener.super.onRenderedFirstFrame();
      }

    });

    Timer timer = new Timer();
    timer.schedule(new TimerTask() {
      @Override
      public void run() {
        mHandler.post(new Runnable() {
          @Override
          public void run() {
            mIv.setImageBitmap(mTextureView.getBitmap());
          }
        });

      }
    }, 5000, 1000);



    mTextureView.setSurfaceTextureListener(
        new TextureView.SurfaceTextureListener() {
          @Override
          public void onSurfaceTextureAvailable(@NonNull SurfaceTexture surface, int width,
              int height) {
            Log.d("duruochen111", "onSurfaceTextureAvailable");
            mExoPlayer.setVideoTextureView(mTextureView);


          }

          @Override
          public void onSurfaceTextureSizeChanged(@NonNull SurfaceTexture surface, int width,
              int height) {
            Log.d("duruochen111", "onSurfaceTextureSizeChanged");
            mExoPlayer.setVideoTextureView(mTextureView);
          }

          @Override
          public boolean onSurfaceTextureDestroyed(@NonNull SurfaceTexture surface) {
            return false;
          }

          @Override
          public void onSurfaceTextureUpdated(@NonNull SurfaceTexture surface) {
            Log.d("duruochen111", "onSurfaceTextureUpdated");
          }
        }
    );
  }

  @Override
  protected void onDestroy() {
    super.onDestroy();
    if (mExoPlayer != null) {
      mExoPlayer.release();
    }
  }

  String manifest_string =
      "{\n" +
          "    \"version\": \"1.0.0\",\n" +
          "    \"adaptationSet\": [\n" +
          "        {\n" +
          "            \"duration\": 1000,\n" +
          "            \"id\": 1,\n" +
          "            \"representation\": [\n" +
          "                {\n" +
          "                    \"id\": 1,\n" +
          "                    \"codec\": \"avc1.64001e,mp4a.40.5\",\n" +
          "                    \"url\": \"http://las-tech.org.cn/kwai/las-test_ld500d.flv\",\n" +
          "                    \"backupUrl\": [],\n" +
          "                    \"host\": \"las-tech.org.cn\",\n" +
          "                    \"maxBitrate\": 700,\n" +
          "                    \"width\": 640,\n" +
          "                    \"height\": 360,\n" +
          "                    \"frameRate\": 25,\n" +
          "                    \"qualityType\": \"SMOOTH\",\n" +
          "                    \"qualityTypeName\": \"流畅\",\n" +
          "                    \"hidden\": false,\n" +
          "                    \"disabledFromAdaptive\": false,\n" +
          "                    \"defaultSelected\": false\n" +
          "                },\n" +
          "                {\n" +
          "                    \"id\": 2,\n" +
          "                    \"codec\": \"avc1.64001f,mp4a.40.5\",\n" +
          "                    \"url\": \"http://las-tech.org.cn/kwai/las-test_sd1000d.flv\",\n" +
          "                    \"backupUrl\": [],\n" +
          "                    \"host\": \"las-tech.org.cn\",\n" +
          "                    \"maxBitrate\": 1300,\n" +
          "                    \"width\": 960,\n" +
          "                    \"height\": 540,\n" +
          "                    \"frameRate\": 25,\n" +
          "                    \"qualityType\": \"STANDARD\",\n" +
          "                    \"qualityTypeName\": \"标清\",\n" +
          "                    \"hidden\": false,\n" +
          "                    \"disabledFromAdaptive\": false,\n" +
          "                    \"defaultSelected\": true\n" +
          "                },\n" +
          "                {\n" +
          "                    \"id\": 3,\n" +
          "                    \"codec\": \"avc1.64001f,mp4a.40.5\",\n" +
          "                    \"url\": \"http://las-tech.org.cn/kwai/las-test.flv\",\n" +
          "                    \"backupUrl\": [],\n" +
          "                    \"host\": \"las-tech.org.cn\",\n" +
          "                    \"maxBitrate\": 2300,\n" +
          "                    \"width\": 1280,\n" +
          "                    \"height\": 720,\n" +
          "                    \"frameRate\": 30,\n" +
          "                    \"qualityType\": \"HIGH\",\n" +
          "                    \"qualityTypeName\": \"高清\",\n" +
          "                    \"hidden\": false,\n" +
          "                    \"disabledFromAdaptive\": false,\n" +
          "                    \"defaultSelected\": false\n" +
          "                }\n" +
          "            ]\n" +
          "        }\n" +
          "    ]\n" +
          "}";
}
