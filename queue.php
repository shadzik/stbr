<?
// Builder queue parser class 
// Piotr Budny, vip at pld-linux dot org

class Queue
{
	//var $xmlqueuepath = "queue.gz";
	var $xmlqueuepath = '';
	var $queue = '';

	public function __construct($xmlqueuepath)
	{
		$this->xmlqueuepath = $xmlqueuepath;
	}

	function array_preg_search($data, $search)
	{
		foreach($data as $key => $value)
		{
			if(trim($value) == $search)
			{
				return $key;
			}
		}
		return false;
	}

	function gzfile_get_contents($file)
	{	
		$data = '';
		$data = gzfile($file);
	
		$pgp_start = $this->array_preg_search($data, "<queue>");
		$pgp_length = $this->array_preg_search($data, "</queue>") - $pgp_start + 1;
	
		$data = array_slice($data, $pgp_start, $pgp_length);
		$data = implode($data);
		
		return $data; 
	} 
	
	function convert_to_timestamp(&$element, $key)
	{
		$element['date'] = strtotime($element['date']);
	}
	
	function queue_search_recursive($spec)
	{
		$result = array();
	
		foreach($this->queue as $group)
		{
			$queue_requster = (string)$group->requester;
			$queue_date = (int)$group->time;
			$queue_flags = (string)$group->Attributes()->flags;
			$queue_no = (string)$group->Attributes()->no;

			foreach($group->batch as $batch)
			{
				$queue_spec = (string)$batch->spec;
		
				if($spec['spec'] != $queue_spec)
					continue;
				
				if($spec['builder'] != $queue_flags)
					continue;
	
				if($spec['date'] <= $queue_date)
				{
					$builder = array();

					foreach($group->batch->builder as $b)
					{
						$builder[(string)$b] = (string)$b->Attributes()->status;
					}
					$result = array('date' => $queue_date,
							'requester' => $queue_requster,
							'flags' => $queue_flags,
							'no' => $queue_no,
							'builder' => $builder
						);
				}
			}
		}
	
		return $result;
	}
	
	function prepare_queue_data()
	{
		if(empty($this->queue))
		{
			$this->queue = $this->gzfile_get_contents($this->xmlqueuepath);
			$this->queue = simplexml_load_string($this->queue);
		}
	}
	
	function is_filled($spec)
	{
		$status = array();
		$this->prepare_queue_data();
		$spec['date'] = strtotime($spec['date']);
		$status = $this->queue_search_recursive($spec);
		
		return $status;
	}
}	

?>
