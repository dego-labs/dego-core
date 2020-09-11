let degoSegment = {};
let playerMap = {};

function updateDegoSegment(index, min, max) {
  let config = {};
  config.min = min;
  config.max = max;
  degoSegment[index] = config;
}
updateRuler(10000, updateDegoSegment);

function updateRuler(maxCount, func) {
  //console.log("updateRuler", maxCount)
  let ruler = [0.8, 0.1, 0.1];
  let factor = [1, 3, 5];

  let lastBegin = 0;
  let lastEnd = 0;
  let splitPoint = 0;
  for (let i = 1; i <= ruler.length; i++) {
    splitPoint = Math.floor(maxCount * ruler[i - 1]);
    if (splitPoint <= 0) {
      splitPoint = 1;
    }
    //console.log("----->", i, "----", lastBegin + 1, "----", lastEnd,"----",splitPoint)
    lastEnd = lastBegin + splitPoint;
    if (i == ruler.length) {
      lastEnd = maxCount;
    }
    func(i, lastBegin + 1, lastEnd);
    //console.log("----->", i, "----", lastBegin + 1, "----", lastEnd, "-----dt", lastEnd - lastBegin)
    lastBegin = lastEnd;
  }
}

let high = 3;
let mid = 2;
let low = 1;

let countSegment = {}
countSegment[high] = {};
countSegment[high].length = 10;
countSegment[high].curCount = 0;
countSegment[high].playerIds = {};

countSegment[mid] = {};
countSegment[mid].length = 10;
countSegment[mid].curCount = 0;
countSegment[mid].playerIds = {};

countSegment[low] = {};
countSegment[low].length = 80;
countSegment[low].curCount = 0;
countSegment[low].playerIds = {};

function checkCountSegmentSlot(segIndex) {
  let value = countSegment[segIndex].length - countSegment[segIndex].curCount;
  if (value > 0) {
    return true;
  } else {
    return false;
  }
}

// function findSegmentMinPlayer(segIndex) {
//   let minAmount = degoSegment[segIndex].max;
//   let oldMinAmount = degoSegment[segIndex].min;
//   let minPlayerOffSet = 0;
//   for (let i = 0; i < countSegment[segIndex].curCount; i++) {
//     //console.log(countSegment[segIndex].playerIds)
//     let playerId = countSegment[segIndex].playerIds[i];
//     if (playerId > 0 && playerMap[playerId].amount < minAmount) {
//       if (minAmount < degoSegment[segIndex].max) {
//         oldMinAmount = minAmount;
//       }
//       minAmount = playerMap[playerId].amount;
//       minPlayerOffSet = i;
//     }
//   }



//   return {
//     index: minPlayerOffSet,
//     amount: oldMinAmount
//   }
// }


function findSegmentMinPlayer(segIndex) {
  let firstMinAmount = degoSegment[segIndex].max;
  let secondMinAmount = degoSegment[segIndex].max;
  let minPlayerOffset = 0;
  for (let i = 0; i < countSegment[segIndex].curCount; i++) {
    let playerId = countSegment[segIndex].playerIds[i];
    if (playerId == 0) {
      continue;
    }
    let amount = playerMap[playerId].amount;

    //console.log(">>>>>>>>>>>>1",amount," 1:",firstMinAmount," 2:",secondMinAmount)

    //find min amount;
    if (amount < firstMinAmount) {
      if (firstMinAmount < secondMinAmount) {
          secondMinAmount = firstMinAmount;
      }
      firstMinAmount = amount;
      minPlayerOffset = i;
    } else {
      //find second min amount
      if (amount < secondMinAmount) {
        secondMinAmount = amount;
      }
    }
  }


  return {
    index: minPlayerOffset,
    amount: secondMinAmount

  }
}



  let G_playerId = 0;
  let nameXId = {};

  function determinPlayer(name) {
    let playerId = nameXId[name];
    if (playerMap[playerId]) {
      return playerId;
    } else {
      G_playerId++;
      nameXId[name] = G_playerId;
      return G_playerId;
    }
  }


  //swap the player data from old segment to the new segment
  function segMentSwap(playerId, segIndex) {

    let oldSegIndex = playerMap[playerId].segIndex;
    let oldOffSet = playerMap[playerId].offSet;
    let tail = countSegment[segIndex].curCount;

    playerMap[playerId].segIndex = segIndex;
    playerMap[playerId].offSet = tail;

    countSegment[segIndex].curCount = countSegment[segIndex].curCount + 1;
    countSegment[segIndex].playerIds[tail] = playerId;

    // if (segIndex == 1) {
    //   console.log("segIndex:", segIndex, countSegment[segIndex].playerIds, "count", countSegment[segIndex].curCount, "oldSegIndex", oldSegIndex, " playerId", playerId, " oldOffSet", oldOffSet)
    // }
    //remove
    if (oldSegIndex > 0 && segIndex != oldSegIndex && countSegment[oldSegIndex].playerIds[oldOffSet] > 0) {

      let originTail = countSegment[oldSegIndex].curCount - 1;
      let originTailPlayer = countSegment[oldSegIndex].playerIds[originTail];

      // if (segIndex == 3) {
      //   console.log("fuck1!!!!", playerId, segIndex)
      //   console.log("shit!!!!!!", oldSegIndex, oldOffSet, originTailPlayer, originTail)
      // }
      if (originTailPlayer != playerId) {
        playerMap[originTailPlayer].segIndex = oldSegIndex;
        playerMap[originTailPlayer].offSet = oldOffSet;
        countSegment[oldSegIndex].playerIds[oldOffSet] = originTailPlayer
      }
      countSegment[oldSegIndex].playerIds[originTail] = 0;
      countSegment[oldSegIndex].curCount--;

      //console.log("------->segIndex:",oldSegIndex,countSegment[oldSegIndex].playerIds)
    }

  }

  //get the leftPlayerId from a segment
  function tailSwap(segIndex) {

    let result = findSegmentMinPlayer(segIndex);
    let minPlayerOffSet = result.index;
    let oldMinAmount = result.amount;
    degoSegment[segIndex].min = oldMinAmount;
    //console.log(">>>>>>>>>>>>>>>>>>",oldMinAmount)

    let leftPlayerId = countSegment[segIndex].playerIds[minPlayerOffSet];

    //segMentSwap to reset
    let tail = countSegment[segIndex].curCount - 1;
    let tailPlayerId = countSegment[segIndex].playerIds[tail];
    countSegment[segIndex].playerIds[minPlayerOffSet] = tailPlayerId;
    playerMap[tailPlayerId].offSet = minPlayerOffSet;

    return leftPlayerId;
  }

  function joinHigh(playerId) {

    //console.log("joinHigh", playerId)
    let segIndex = high;
    if (checkCountSegmentSlot(segIndex)) {
      segMentSwap(playerId, segIndex);
    } else {

      let leftPlayerId = tailSwap(segIndex);
      joinMid(leftPlayerId);
      
      segMentSwap(playerId, segIndex)
    }
  }

  function joinMid(playerId) {
    //console.log("joinMid", playerId)
    let segIndex = mid;
    if (checkCountSegmentSlot(segIndex)) {
      segMentSwap(playerId, segIndex);
    } else {
      let leftPlayerId = tailSwap(segIndex)
      joinLow(leftPlayerId);
      segMentSwap(playerId, segIndex)

    }
    degoSegment[segIndex].max = degoSegment[segIndex+1].min;
  }

  function joinLow(playerId) {

    let segIndex = low;
    segMentSwap(playerId, segIndex);
    
    degoSegment[segIndex].max = degoSegment[segIndex+1].min;
    //low segment length update
    if (countSegment[segIndex].curCount > countSegment[segIndex].length) {
      countSegment[segIndex].length = countSegment[segIndex].curCount;
    }

  }

  function updateCountSegment() {
    let base = 100;
    let anchor = base;
    let grouthStep = 10;
    let highMax = 50;
    let midMax = 50;

    if (G_playerId - anchor >= grouthStep) {
      if (countSegment[high].length + grouthStep > highMax) {
        countSegment[high].length = highMax;
      } else {
        countSegment[high].length += grouthStep
      }

      if (countSegment[mid].length + grouthStep > midMax) {
        countSegment[mid].length = midMax;
      } else {
        countSegment[mid].length += grouthStep
      }
      anchor = G_playerId;
    }
  }

  function join(name, amount) {

    updateCountSegment();

    let segIndex = 0;
    for (let i = 1; i <= high; i++) {
      if (amount < degoSegment[i].max) {
        segIndex = i;
        break;
      }
    }

    if (segIndex == 0) {
      degoSegment[high].max = amount;
      segIndex = high;
    }

    let playerId = determinPlayer(name, amount);
    playerMap[playerId] = {
      name: name,
      playerId: playerId,
      amount: amount,
      segIndex: 0,
      offSet: 0
    }
    if (segIndex == high) {
      joinHigh(playerId);
    } else if (segIndex == mid) {
      joinMid(playerId);
    } else {
      joinLow(playerId);
    }
  }

  function change(playerId, amount) {

    //console.log("change playerId,amount",playerId,amount)
    let segIndex = 0;
    for (let i = 1; i <= high; i++) {
      if (amount < degoSegment[i].max) {
        segIndex = i;
        break;
      }
    }
    if (segIndex == 0) {
      degoSegment[high].max = amount;
      segIndex = high;
    }

    if (playerMap[playerId]) {

      playerMap[playerId].amount = amount;
      if (playerMap[playerId].segIndex == segIndex) {
        return;
      }

      if (segIndex == high) {
        joinHigh(playerId);
      } else if (segIndex == mid) {
        joinMid(playerId);
      } else {
        joinLow(playerId);
      }

    }
  }

  console.log(degoSegment)
  ///////////////////////
  let base = 400;
  let max = 550;
  for (let i = 0; i < max; i++) {
    join("name_" + i, i * 100);
  }

  console.log(degoSegment)
  console.log(countSegment)


  // join("name_" + 1, 800);
  // join("name_" + 2, 900);
  // join("name_" + 12, 900);
  // change(1, 8500)

  for (let i = base; i < max; i++) {
    change(i, 8500)
  }

  console.log(countSegment)


  for (let i = base; i < max; i++) {
    change(i, 9500)
  }
  console.log(countSegment)


  for (let i = base; i < max; i++) {
    change(i, 9600)
  }
  console.log(countSegment)


  for (let i = base; i < max; i++) {
    change(i, 198000)
  }
  console.log(countSegment)
  //console.log(playerMap)


  console.log(degoSegment)


  // join("name_" + 1, 850);
  // join("name_" + 2, 850);
  // join("name_" + 3, 850);

  // join("name_" + 4, 899);
  // join("name_" + 5, 999);
  // join("name_" + 6, 999);

  // join("name_" + 7, 999);
  // join("name_" + 8, 1000);
  // change(1, 1000);

  // console.log(countSegment)
  // console.log(degoSegment)
