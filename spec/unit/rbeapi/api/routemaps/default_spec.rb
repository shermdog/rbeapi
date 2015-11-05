#
# Copyright (c) 2015, Arista Networks, Inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
#   Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
#
#   Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
#   Neither the name of Arista Networks nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL ARISTA NETWORKS
# BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
# BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
# OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
# IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
require 'spec_helper'

require 'rbeapi/api/routemaps'

include FixtureHelpers

describe Rbeapi::Api::Routemaps do
  subject { described_class.new(node) }

  let(:node) { double('node') }

  let(:test) do
    [
      {
        action: 'permit',
        seqno: 10,
        match: ['interface Loopback0', 'ip address prefix-list MYLOOPBACK'],
        set: ['community internet 5555:5555'],
        continue: 99,
        description: 'description'
      }
    ]
  end
  let(:name) { 'test1' }

  def routemaps
    routemaps = Fixtures[:routemaps]
    return routemaps if routemaps
    fixture('routemaps', format: :text, dir: File.dirname(__FILE__))
  end

  before :each do
    allow(subject.node).to receive(:running_config).and_return(routemaps)
  end

  describe '#getall' do
    let(:test1_entries) do
      {
        'test1' => [{ action: 'permit', seqno: 10,
                      match: ['interface Loopback0',
                              'ip address prefix-list MYLOOPBACK'],
                      set: ['community internet 5555:5555'],
                      continue: 99,
                      description: 'description' }],
        'test' => [{ action: 'permit', seqno: 10,
                     match: ['interface Vlan100'],
                     continue: 99,
                     description: 'description' },
                   { action: 'permit', seqno: 20,
                     description: 'description',
                     continue: 99,
                     set: ['community internet 5555:5555']
                   }]
      }
    end

    it 'returns the routemap collection' do
      expect(subject.getall).to include(test1_entries)
    end

    it 'returns a hash collection' do
      expect(subject.getall).to be_a_kind_of(Hash)
    end

    it 'has two entries' do
      expect(subject.getall.size).to eq(2)
    end
  end

  describe '#get' do
    it 'returns the routemap resource for given name' do
      expect(subject.get(name)).to eq(test)
    end

    it 'returns a hash' do
      expect(subject.get(name)).to be_a_kind_of(Array)
    end

    it 'has two entries' do
      expect(subject.get(name).size).to eq(1)
    end
  end

  describe '#create' do
    it 'create a new routemap' do
      expect(node).to receive(:config).with(['route-map test1 permit 10'])
      expect(subject.create('test1', 'permit', 10)).to be_truthy
    end

    it 'create a new routemap with description' do
      expect(node).to receive(:config)
        .with(['route-map test1 permit 10', 'no description',
               'description description',
               'no match interface Loopback0',
               'no match ip address prefix-list MYLOOPBACK',
               'no set community internet 5555:5555'])
      expect(subject.create('test1', 'permit', 10,
                            description: 'description')).to be_truthy
    end

    it 'create a new routemap with match' do
      expect(node).to receive(:config)
        .with(['route-map test1 permit 10',
               'no match interface Loopback0',
               'no match ip address prefix-list MYLOOPBACK',
               'match ip address prefix-list MYLOOPBACK',
               'match interface Loopback0',
               'no set community internet 5555:5555'])
      expect(subject.create('test1', 'permit', 10,
                            match: ['ip address prefix-list MYLOOPBACK',
                                    'interface Loopback0'])).to be_truthy
    end

    it 'create a new routemap with set' do
      expect(node).to receive(:config)
        .with(['route-map test1 permit 10',
               'no match interface Loopback0',
               'no match ip address prefix-list MYLOOPBACK',
               'no set community internet 5555:5555',
               'set community internet 5555:5555'])
      expect(subject.create('test1', 'permit', 10,
                            set: ['community internet 5555:5555'])).to be_truthy
    end

    it 'create a new routemap with continue' do
      expect(node).to receive(:config)
        .with(['route-map test1 permit 10', 'no continue', 'continue 99',
               'no match interface Loopback0',
               'no match ip address prefix-list MYLOOPBACK',
               'no set community internet 5555:5555'])
      expect(subject.create('test1', 'permit', 10,
                            continue: 99)).to be_truthy
    end

    it 'create a new routemap with default' do
      expect(node).to receive(:config)
        .with(['default route-map test1 permit 10',
               'no match interface Loopback0',
               'no match ip address prefix-list MYLOOPBACK',
               'no set community internet 5555:5555'])
      expect(subject.create('test1', 'permit', 10,
                            default: true)).to be_truthy
    end
  end

  describe '#delete' do
    it 'delete a routemap resource' do
      expect(node).to receive(:config).with(['no route-map test1'])
      expect(subject.delete('test1')).to be_truthy
    end
  end

  describe '#set_match_statements' do
    it 'set the match statements' do
      expect(node).to receive(:config)
        .with(['route-map test1 permit 10',
               'no match interface Loopback0',
               'no match ip address prefix-list MYLOOPBACK',
               'match ip address prefix-list MYLOOPBACK',
               'match interface Loopback0'])
      expect(
        subject
          .set_match_statements('test1', 'permit', 10,
                                ['ip address prefix-list MYLOOPBACK',
                                 'interface Loopback0'])
      ).to be_truthy
      expect(subject.get('test1')[0][:match])
        .to include('ip address prefix-list MYLOOPBACK',
                    'interface Loopback0')
    end
  end

  describe '#set_set_statements' do
    it 'set the set statements' do
      expect(node).to receive(:config)
        .with(['route-map test1 permit 10',
               'no set community internet 5555:5555',
               'set community internet 5555:5555'])
      expect(
        subject.set_set_statements('test1', 'permit', 10,
                                   ['community internet 5555:5555'])
      ).to be_truthy
      expect(subject.get('test1')[0][:set])
        .to include('community internet 5555:5555')
    end
  end

  describe '#set_continue' do
    it 'set the continue statement' do
      expect(node).to receive(:config).with(['route-map test1 permit 10',
                                             'no continue',
                                             'continue 99'])
      expect(subject.set_continue('test1', 'permit', 10, 99)).to be_truthy
      expect(subject.get('test1')[0][:continue]).to eq(99)
    end
  end

  describe '#set_description' do
    it 'set the description statement' do
      expect(node).to receive(:config).with(['route-map test1 permit 10',
                                             'no description',
                                             'description description'])
      expect(subject.set_description('test1', 'permit', 10,
                                     'description')).to be_truthy
      expect(subject.get('test1')[0][:description]).to eq('description')
    end
  end
end
