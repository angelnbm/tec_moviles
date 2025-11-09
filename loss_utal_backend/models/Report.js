const mongoose = require('mongoose');

const ReportSchema = new mongoose.Schema({
  title: { 
    type: String, 
    required: true 
  },
  description: { 
    type: String, 
    required: true 
  },
  category: { 
    type: String, 
    enum: ['found', 'lost'], 
    required: true 
  },
  location: { 
    type: String, 
    required: true 
  },
  latitude: { 
    type: Number 
  },
  longitude: { 
    type: Number 
  },
  imageUrl: { 
    type: String 
  },
  audioUrl: { 
    type: String 
  },
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  status: { 
    type: String, 
    enum: ['active', 'resolved'], 
    default: 'active' 
  },
  createdAt: { 
    type: Date, 
    default: Date.now 
  }
});

module.exports = mongoose.model('Report', ReportSchema);
