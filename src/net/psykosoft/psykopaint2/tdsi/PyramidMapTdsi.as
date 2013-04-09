package net.psykosoft.psykopaint2.tdsi
{
	import flash.display.BitmapData;
	import flash.display3D.textures.Texture;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import apparat.asm.DecLocalInt;
	import apparat.asm.IncLocalInt;
	import apparat.asm.__asm;
	import apparat.asm.__cint;
	import apparat.memory.Memory;
	

	public class PyramidMapTdsi
	{
		private var _offsets:Vector.<int>;
		//private var _offsets:Vector.<Matrix>;
		
		private var _data:ByteArray;
		private var width:int;
		private var height:int;
		
		private const ilog2:Number = 1 / Math.log(2);
		private const i255:Number = 1 / 255;
		private var _baseOffset:int;

		
		
		public function PyramidMapTdsi( sourceMap:BitmapData )
		{
			setSource( sourceMap );
		}

		public function dispose() : void
		{
			//TODO - allow memory manager to release memory
		}
		
		public function setSource( map:BitmapData ):void
		{
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
			var offset:int =  width*height*4;
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
			
			_baseOffset = MemoryManagerTdsi.reserveMemory( width * height * 4 + offset);
			_data = MemoryManagerTdsi.memory;
			
			_data.position = _baseOffset;
			_data.writeBytes(  map.getPixels(map.rect) );
			
			for ( i = 0; i < r.length; i++ )
			{
				_offsets[i] += _baseOffset;
				_data.writeBytes( _scaled.getPixels(r[i]) );
			}
			
			
			var j:int = _baseOffset + width * height * 4 + offset - 4;
			while ( j >= _baseOffset )
			{
				var d:int = Memory.readInt(j );
				Memory.writeInt( ((d >> 24) & 0xff) | ((d >> 8) & 0xff00)  | ((d << 8) & 0xff0000) | ((d  & 0xff) << 24), j );
				j = __cint(j-4);
					
			}
			
			_scaled.dispose();
			
		}
		
		public function getRGB( x:Number, y:Number, radius:Number, target:Vector.<Number> ):void
		{
			
			var xx:int = x + 0.5;
			var yy:int = y +0.5;
			
			
			if ( xx < 0 ) xx = 0;
			else if ( xx >= width ) xx = __cint(width - 1);
			if ( yy < 0 )yy = 0;
			else if ( yy >= height ) yy =__cint(height - 1);
			radius *= 0.5;
			var offset:int = _baseOffset + ((xx + yy * width) << 2 );
			if (radius <= 1 )
			{
				var c:uint = Memory.readInt(offset);
				
				target[0] = (( c >>> 16 ) & 0xff) * i255;
				target[1] = (( c >>> 8 ) & 0xff) * i255;
				target[2] = (c  & 0xff) * i255;
				return;
			}
			
			var index:int = -1;
			var stride:int = width;
			var scaledRadius:int = radius+0.5;
			while ( scaledRadius > 1 && index < _offsets.length - 1)
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
			if ( index >= _offsets.length ) index = _offsets.length-1;
			
			var v2:uint = Memory.readInt( __cint(_offsets[index] + ((xx + yy * stride) << 2)));
			
			var f:Number = 2 - Math.pow(2, radius / Math.pow(2,index) - 1 );
			
			var r1:Number = ((v1 >>> 16) & 0xff);
			var g1:Number = ((v1 >>> 8) & 0xff);
			var b1:Number = (v1  & 0xff);
			
			var r2:Number = ((v2 >>> 16) & 0xff);
			var g2:Number = ((v2 >>> 8) & 0xff);
			var b2:Number = (v2  & 0xff);
			
			target[0] = (r2 + ( r1 - r2 ) * f) * i255;
			target[1] =  (g2 + ( g1 - g2 ) * f) * i255;
			target[2] =  (b2 + ( b1 - b2 ) * f) * i255;
			
		}
		
		public function uploadMipLevel( targetTexture:Texture, mipLevel:int ):void 
		{
			var offset:int = _baseOffset + ( mipLevel > 0 ? _offsets[mipLevel-1] : 0 ); 
			targetTexture.uploadFromByteArray(_data,offset,mipLevel);
		}
	}
}