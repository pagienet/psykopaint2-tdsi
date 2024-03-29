package net.psykosoft.psykopaint2.tdsi
{
	import flash.display.BitmapData;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	
	import apparat.asm.__cint;
	import apparat.memory.Memory;
	

	public class PyramidMapTdsi
	{
		private var _offsets:Vector.<int>;
		private var _maxOffsetCount:int;
		
		private var _data:ByteArray;
		private var width:int = -1;
		private var height:int = -1;
		private var scaleFactor:Number = 1;
		
		private const ilog2:Number = 1 / Math.log(2);
		private const i255:Number = 1 / 255;
		private var _baseOffset:int = -1;
		
		private const MAX_DIMENSION:int = 1024;
		
		
		public function PyramidMapTdsi( sourceMap:BitmapData )
		{
			setSource( sourceMap );
		}

		public function dispose() : void
		{
			_offsets.length = 0;
			_offsets = null;
			_data = null;
			
		}
		
		public function setSource( map:BitmapData ):void
		{
			if ( width != -1 && ( width != map.width || height != map.height ))
			{
				throw( new Error("PyramidMapTdsi: source map size cannot change once it has been set once!!!! Sorry, we were in a hurry and needed the money. Time to fix memory management, buddy."));	
			}
			
			scaleFactor = Math.min( 1, MAX_DIMENSION / map.width, MAX_DIMENSION / map.height );
			if ( scaleFactor != 1 )
			{
				//this solution is not ideal since it requires temporary memory allocation,
				//but I ran into issues when trying to do the scale down in a "smarter" way. Bonus points for whoever improves it.
				var tmpMap:BitmapData = new BitmapData( map.width*scaleFactor, map.height*scaleFactor, false, 0);
				tmpMap.draw( map, new Matrix(scaleFactor,0,0,scaleFactor), null, "normal",null,true )
				map = tmpMap;
			}
			
			
			width = map.width;
			height = map.height;
			
			var _scaled:BitmapData = new BitmapData(Math.ceil(width * 0.75), Math.ceil(height * 0.5), true, 0 );
			var m:Matrix = new Matrix(0.5,0,0,0.5);
			_scaled.draw( map, m, null, "normal",null,true);
			m.tx += width * 0.5;
			_scaled.draw( _scaled, m, null, "normal",null,true);
			m.ty += height * 0.25;
			m.a = m.d *= 0.5;
			_scaled.draw( _scaled, m, null, "normal",null,true);
			m.a = m.d *= 0.25;
			m.tx += width * 0.125;
			m.ty += height * 0.0625;
			_scaled.draw( _scaled, m, null, "normal",null,true);
			
			var f:Number = 1;
			var r:Vector.<Rectangle> = new Vector.<Rectangle>();
			var rect:Rectangle = new Rectangle(0,0,width*0.5,height*0.5);
			r.push(rect.clone());
			
			_offsets = new Vector.<int>();
			var offset:int = 0;
			offset +=  width*height*4;
			_offsets.push( offset);
			
			for ( var i:int = 0; i < 6; i++ )
			{
				offset += rect.width * rect.height * 4; 
				rect.width >>= 1;
				rect.height >>= 1;
				if ( rect.width == 0 || rect.height == 0 ) break;
				rect.x += int(width * (f *= 0.5));
				r.push(rect.clone());
				
				_offsets.push(offset);
				
				offset += rect.width * rect.height * 4; 
				rect.width  >>= 1;
				rect.height >>= 1;
				if ( rect.width == 0 || rect.height == 0 ) break;
				rect.y += int(height * (f *= 0.5));
				r.push(rect.clone());
				
				_offsets.push(offset);
			}
			
			if ( _baseOffset == -1 )
				_baseOffset = MemoryManagerTdsi.reserveMemory( offset);
			
			_data = MemoryManagerTdsi.memory;
			
			_data.position = _baseOffset;
			_data.writeBytes(  map.getPixels(map.rect) );
			
			for ( i = 0; i < r.length; i++ )
			{
				_offsets[i] += _baseOffset;
				_data.writeBytes( _scaled.getPixels(r[i]) );
			}
			
			_maxOffsetCount = _offsets.length - 1;
			/*
			var j:int = _baseOffset + offset - 4; 
			while ( j >= _baseOffset )
			{
				var d:int = Memory.readInt(j );
				Memory.writeInt( ((d >> 24) & 0xff) | ((d >> 8) & 0xff00)  | ((d << 8) & 0xff0000) | ((d  & 0xff) << 24), j );
				j = __cint(j-4);
			}
			*/
			
			_scaled.dispose();
			if ( scaleFactor != 1 ) map.dispose();
		}
		
		public function getRGB( x:Number, y:Number, radius:Number, target:Vector.<Number> ):void
		{
			
			var xx:int = x * scaleFactor + 0.5;
			var yy:int = y * scaleFactor + 0.5;
			
			
			if ( xx < 0 ) xx = 0;
			else if ( xx >= width ) xx = __cint(width - 1);
			if ( yy < 0 )yy = 0;
			else if ( yy >= height ) yy =__cint(height - 1);
			radius *= 0.5 * scaleFactor;
			var offset:int = _baseOffset + ((xx + yy * width) << 2 );
			if (radius <= 1 )
			{
				var c:uint = Memory.readInt(offset);
				target[0] = (( c >>> 8 ) & 0xff) * i255;
				target[1] = (( c >>> 16 ) & 0xff) * i255;
				target[2] = (( c >>> 24 ) & 0xff) * i255;
				return;
			}
			
			var index:int = -1;
			var stride:int = width;
			var scaledRadius:int = radius+0.5;
			while ( scaledRadius > 1 && index < _maxOffsetCount)
			{
				scaledRadius >>= 1;
				index++;
				xx >>= 1;
				yy >>= 1;
				stride >>= 1;
			}
			
			if ( index >= 0 )
			{
				var v1:uint = Memory.readInt( __cint(_offsets[index] + ((xx + yy * stride) << 2) ));
			} else {
				v1 = Memory.readInt(offset);
			}
			
			xx >>= 1;
			yy >>= 1;
			stride >>= 1;
			index++;
			if ( index >= _maxOffsetCount + 1 ) index = _maxOffsetCount;
			
			var v2:uint = Memory.readInt( __cint(_offsets[index] + ((xx + yy * stride) << 2)));
			
			//var f:Number = 2 - Math.pow(2, radius / Math.pow(2,index) - 1 );
			var f:Number = 2 - Math.pow(2, radius / (1<<index) - 1 );
			
			var r1:Number = ((v1 >>> 8) & 0xff);
			var g1:Number = ((v1 >>> 16) & 0xff);
			var b1:Number = ((v1 >>> 24) & 0xff);
			
			var r2:Number = ((v2 >>> 8) & 0xff);
			var g2:Number = ((v2 >>> 16) & 0xff);
			var b2:Number = ((v2 >>> 24) & 0xff);
			
			target[0] = (r2 + ( r1 - r2 ) * f) * i255;
			target[1] = (g2 + ( g1 - g2 ) * f) * i255;
			target[2] = (b2 + ( b1 - b2 ) * f) * i255;
			
		}
		
		public function uploadMipLevel( targetTexture:Texture, mipLevel:int ):void 
		{
			var offset:int = _baseOffset + ( mipLevel > 0 ? _offsets[mipLevel-1] : 0 ); 
			targetTexture.uploadFromByteArray(_data,offset,mipLevel);
		}
	}
}