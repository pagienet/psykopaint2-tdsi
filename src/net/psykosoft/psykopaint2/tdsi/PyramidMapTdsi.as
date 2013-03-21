package net.psykosoft.psykopaint2.tdsi
{
	import flash.display.BitmapData;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.utils.ByteArray;
	import flash.utils.Endian;
	
	import apparat.asm.__cint;
	import apparat.memory.Memory;
	

	public class PyramidMapTdsi
	{
		private var _offsets:Vector.<Matrix>;
		private var _data:ByteArray;
		private var width:int;
		private var height:int;
		private var scaledStride:int;
		private var _scaledDataOffset:int;
		
		private const ilog2:Number = 1 / Math.log(2);
		private const i255:Number = 1 / 255;
		
		public function PyramidMapTdsi( sourceMap:BitmapData )
		{
			setSource( sourceMap );
		}

		public function dispose() : void
		{
			if ( _data ) _data.length = 0;
		}
		
		public function setSource( map:BitmapData ):void
		{
			width = map.width;
			height = map.height;
			
			var _scaled:BitmapData = new BitmapData(scaledStride = Math.ceil(width * 0.75), Math.ceil(height * 0.5), true, 0 );
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
			m = new Matrix(0.5,0,0,0.5);
			_offsets = new Vector.<Matrix>();
			_offsets.push(m.clone());
			
			for ( var i:int = 0; i < 15; i++ )
			{
				m.a = m.d *= 0.5;
				m.tx += width * (f *= 0.5);
				_offsets.push(m.clone());
				m.a = m.d *= 0.5;
				m.ty += height * (f *= 0.5);
				_offsets.push(m.clone());
			}
			
			_data = new ByteArray();
			_data.endian = Endian.LITTLE_ENDIAN;
			
			var scaledDataOffset:int =  _scaledDataOffset = width * height * 4;
			_data.length =  scaledDataOffset + _scaled.width * _scaled.height * 4;
			
			activateMemory();
			
			_data.position = 0;
			_data.writeBytes( map.getPixels(map.rect) );
			_data.writeBytes( _scaled.getPixels(_scaled.rect) );
			
			_scaled.dispose();
			
		}
		
		public function activateMemory():void
		{
			Memory.select(_data);
		}
		
		public function getRGB( x:Number, y:Number, radius:Number, target:Vector.<Number>, slotOffset:int, colorBlendFactor:Number ):void
		{
			activateMemory();
			if ( x < 0 ) x = 0;
			else if ( x >= width ) x = __cint(width - 1);
			if ( y < 0 )y = 0;
			else if ( y >= height ) y =__cint(height - 1);
			
			var offset:int = (x + y * width) * 24;
			if ( radius <= 1 )
			{
				var c:uint = Memory.readInt(offset);
				target[slotOffset] += ((( c >>> 24 ) & 0xff) * i255 - target[slotOffset] ) * colorBlendFactor;
				target[__cint(slotOffset+1)] += ((( c >>> 16 ) & 0xff) * i255 - target[__cint(slotOffset+1)] ) * colorBlendFactor;
				target[__cint(slotOffset+2)] += ((( c >>> 8 ) & 0xff) * i255 - target[__cint(slotOffset+2)] ) * colorBlendFactor;;
				target[__cint(slotOffset+3)] = 1;
				return;
			}
			
			var scaledDataOffset:int =  _scaledDataOffset;
		
			var index:int = Math.log(radius) * ilog2;
			var rad1:Number = Math.pow(2,index);
			var rad2:Number = Math.pow(2,index + 1);
			
			index-=1;
			if ( index >= 0 )
			{
				var p:Point = _offsets[index].transformPoint( new Point(x,y));
				var v1:uint = Memory.readInt( __cint(scaledDataOffset + (p.x + p.y * scaledStride)* 4 ));
			} else {
				v1 = Memory.readInt(offset);
			}
			
			p = _offsets[index+1].transformPoint( new Point(x,y));
			var v2:uint = Memory.readInt( __cint(scaledDataOffset + (p.x + p.y * scaledStride) * 4));
			
			var f:Number = 2 - Math.pow(2, (radius - rad1) / ( rad2 - rad1 ) );
			
			var r1:Number = ((v1 >>> 8) & 0xff);
			var g1:Number = ((v1 >>> 16) & 0xff);
			var b1:Number = ((v1 >>> 24) & 0xff);
			
			var r2:Number = ((v2 >>> 8) & 0xff);
			var g2:Number = ((v2 >>> 16) & 0xff);
			var b2:Number = ((v2 >>> 24) & 0xff);
			
			target[slotOffset]  += ((r2 + ( r1 - r2 ) * f) * i255 - target[slotOffset] ) * colorBlendFactor;
			target[__cint(slotOffset+1)] += ((g2 + ( g1 - g2 ) * f) * i255 - target[__cint(slotOffset+1)] ) * colorBlendFactor;;
			target[__cint(slotOffset+2)] += ((b2 + ( b1 - b2 ) * f) * i255 - target[__cint(slotOffset+2)] ) * colorBlendFactor;;;
			target[__cint(slotOffset+3)] = 1;
		}
		
	}
}